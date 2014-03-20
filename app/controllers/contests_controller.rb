  require 'openssl'
  require 'cgi'
  require 'prime'


    #Taken on 2014-03-02
  def extended_gcd(a, b)
  x = 0
  y = 1
  u = 1
  v = 0 
    while a != 0 do
          q, r = (b/a).floor, b%a
          m, n = x-u*q, y-v*q
          b,a = a,r
          x,y = u,v
          u,v = m,n
    end
    return b,x,y
  end

  def ASCII_decode (encoded)
    decoded = ""
    (0..(encoded.length)).step(2) do|n|
      asciiChar = encoded[n].to_s + encoded[n+1].to_s
      decoded = decoded + asciiChar.to_i.chr
    end
    return decoded
  end

class Integer #modular exponentiation used in dojo7
      def rosetta_mod_exp(exp, mod)
        exp < 0 and raise ArgumentError, "negative exponent"
        prod = 1
        base = self % mod
        until exp.zero?
          exp.odd? and prod = (prod * base) % mod
          exp >>= 1
          base = (base * base) % mod
        end
        prod
      end
    end

  class ContestsController < ApplicationController
    protect_from_forgery
    before_filter :authenticate_user!, :except => [:show, :index]
    authorize_resource except: [:problem, :solution]
    skip_authorization_check only: [:problem, :solution]

    def num2s_helper number, digit 
      powerOfTen = 10**digit
      nextPowerOfTen = powerOfTen * 10
      right = number % powerOfTen

      roundDown = number - number % nextPowerOfTen
      roundUp = roundDown + nextPowerOfTen
      
      digit = Integer((number / powerOfTen) % 10)
      if digit < 2
        return Integer(roundDown / 10)
      elsif digit == 2
        return Integer((roundDown / 10) + right + 1)
      else
        return Integer(roundUp / 10)
      end
    end

    # GET /contests
    # GET /contests.xml
    def index
      @contests = Contest.all

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @contests }
      end
    end

    # GET /contests/1
    # GET /contests/1.xml
    def show
      @contest = Contest.find(params[:id])
      @num_probs = @contest.puzzle_ident == 3 ? 3 : 2
      if @contest.puzzle_ident == 7
        @num_probs = 4 #nowieveniwouldcelebrate
      end
      if @contest.puzzle_ident == 5
        @num_probs = 5
      end
      if @contest.puzzle_ident == 6
        @num_probs = 4
      end
      if @contest.start > DateTime.now
        unless current_user.is_admin
          redirect_to contests_path, alert: "That contest has not yet started"
          return
        end
      end

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @contest }
      end
    end

    def problem
      @contest = Contest.find(params[:contest_id])
      contest_ident = @contest.puzzle_ident
      @level = params[:level].to_i
      if !current_user.puzzle_available? contest_ident, @level
        redirect_to @contest, alert: "That puzzle isn't available to you yet"
        return
      end

      @max_time_allowed = 120

      # To add more dojos, add another elsif contest_ident == statement. In the
      # block, simply add another elsif block for the appropriate contest_ident
      # which sets the "args" variable to be the array of arguments which will be
      # passed to the puzzle generator function (see contests_helper.rb for more
      # detail.
      args = []
      if contest_ident == 1
        unless (0..2).member? @level
          redirect_to @contest, alert: "Invalid level"
          return
        end
        puzzle_length = [350, 100, 100]
        puzzle_words = [20, 5, 5]
        args = [puzzle_length[@level], puzzle_words[@level]]
      elsif contest_ident == 2
        unless (0..2).member? @level
          redirect_to @contest, alert: "Invalid level"
          return
        end
      elsif contest_ident == 3
        unless (0..3).member? @level
          redirect_to @contest, alert: "Invalid level"
          return
        end
      elsif contest_ident == 4
        unless (0..2).member? @level
          redirect_to @contest, alert: "Invalid level"
          return
        end
        @max_time_allowed = case @level
                            when 0 then 120
                            when 1 then 120
                            when 2 then 300
                            end
      elsif contest_ident == 5
        unless (0..5).member? @level
          redirect_to @contest, alert: "Invalid level"
          return
        end
      elsif contest_ident == 6
        unless (0..4).member? @level
          redirect_to @contest, alert: "Invalid level"
          return
        end
      elsif contest_ident == 7
        unless (0..3).member? @level #nowieveniwouldcelebrate
          redirect_to @contest, alert: "Invalid level"
          return
        end  
      else
        redirect_to @contest, alert: "Invalid contest"
      end

      problem = "dojo#{contest_ident}_level#{@level}"
      @prob = ContestsHelper.generate_puzzle(contest_ident,
        @level, args)

      # For making sure the solution is within the time limit
      session[:time] = Time.now.to_i
      # Used to avoid people trying to cheat by changing the puzzle in the form
      msg = ""
      if contest_ident == 1
        msg = @prob[:puzzle] + @prob[:words].join('')
      elsif contest_ident == 2
        if @level == 0
          msg = @prob[:query] + @prob[:posts].map{|x| x[0]}.join('+')
        elsif @level > 0
          msg = @prob[:searches].map{|x| x[0]}.join('+') + @prob[:locations].join('+')
        end
      elsif contest_ident == 3
        aes = OpenSSL::Cipher::Cipher.new("AES-128-CBC")
        aes.encrypt
        aes.pkcs5_keyivgen(ENV['ENC_PASS'] || "foobar",
                           ENV['ENC_SALT'] || "sodiumcl")
        cipher =  aes.update(@prob[:plaintext])
        cipher << aes.final
        session[:soln] = cipher.unpack('H*').join
        msg = ''
      elsif contest_ident == 4
        msg = @prob[:riddle]
        if @level != 0
          msg = @prob[:riddle].join('')
        end
      elsif contest_ident == 6
        if @level == 2
          msg = @prob[:clubs] + @prob[:course]
        elsif @level == 1
          msg = @prob[:usernames]
        elsif @level >= 3
          msg = @prob[:searches].map{|x| x[0]}.join('+') + @prob[:locations].join('+')
        else 
          msg = @prob[:number]
        end
      elsif contest_ident == 7 #nowieveniwouldcelebrate
        if @level == 0
          msg = @prob[:ciphertext] + @prob[:otp]
        elsif @level == 1
          puts "VIGNERE GREP CONTROLLER"
          msg = @prob[:ciphertext] + @prob[:partial]
        elsif @level == 2
          puts "grep for this:" + @prob[:rsa_ciphertext].to_s + ")(" + @prob[:publicKey].to_s + ")(" + @prob[:exponentN].to_s + ")"
          puts "do these exist? partial(" + @prob[:partial].to_s + "), otp" + @prob[:otp].to_s + ")"
          msg = @prob[:rsa_ciphertext] + @prob[:publicKey] + @prob[:exponentN]
        end
	
      end
      key = ENV['HMAC_KEY'] || "derp"
      session[:key] = OpenSSL::HMAC.hexdigest('sha256', msg, key)

      render problem
    end


    def solution
      contest = Contest.find(params[:contest])
      correct = false
      perf = -1

  if contest.puzzle_ident == 7 #nowieveniwouldcelebrate
        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time
        level = params[:level]
        if time_elapsed > 120  && level.to_i < 3
           redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end
        msg = nil
        if level == "3" or level == "4"
          msg = params[:searches] + params[:locations]
          key = ENV['HMAC_KEY'] || "derp"
          hmac = OpenSSL::HMAC.hexdigest('sha256', msg, key)
          if hmac != session[:key]
            redirect_to contest, alert: 'Cheating detected...'
            return
          end
          session.delete :key
        end
        if time_elapsed > 180 && level >= 3
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end

        if level == '0'
          #one time pad
          ciphertext = params[:ciphertext].to_s
          otp = params[:otp].to_s
          pad = otp

          puts "grep for this: ciphertext:(" + ciphertext + "), otp:(" + otp + "), solution:(" + params[:solution] + ")"
          #puts "@prob: " + @prob[:otp].to_s
          #puts "prob: " + (@prob[:otp]).to_s

          # --- Solution code --- #
          ciphertext_as_array = ciphertext.split(//)
          pad_as_array = pad.split(//)
          plaintext_as_array = Array.new
          plaintext = ""

          for i in 0..ciphertext_as_array.length - 1
            n1 = ciphertext_as_array[i].ord - 65
            n2 = pad_as_array[i].ord - 65
            plaintext_as_array[i] = (n1 - n2)%26
            plaintext_as_array[i] = plaintext_as_array[i] + 65
            plaintext = plaintext + plaintext_as_array[i].chr
          end
          # --- End solution code --- #



          

          mySolution = plaintext
          puts "\n\nmySolution is (" + mySolution + ")\n\n"
          correct = ContestsHelper::Dojo6.verify_level0(
            params[:solution], mySolution
          )
        elsif level == '1'
            #vigenere
            mySolution = ""
            partial = params[:partial].to_s
            # --- Solution code --- #

                set_of_plaintext =[
                'FIFTYPACESNORTHOFTHESTRAWBERRYFARM',
                'NINETYFEETSOUTHOFTHEOLDCHURCH',
                'ONEMILENORTHOFTHEELEMENTARYSCHOOL',
                'THREEMILESSOUTHOFTHECREEPYCIRCUS',
                'SIXTYPACESWESTOFBRANDNEWWHEATMILL',
                'FIVEMILESEASTOFTHESTINKYRUBBERFACTORY',
                'NINETYSILLYWALKSSOUTHOFTHEMINISTRY',
                'JUSTUNDERTHEABANDONEDBRIDGE',
                'RIGHTBEHINDTHENEWLAUNDROMAT',
                'ONTHETHIRDFLOOROFTHETALLESTBUILDING',
                'INTHEBASEMENTOFTHEMAYORSMANOR'
                ]

                set_of_partials =[
                  '.....PACES........................',
                  '...............OFTHE.........',
                  '.................ELEME...........',
                  '..........................CIRCUS',
                  '................BRAND............',
                  '....MILES............................',
                  '...........WALKS..................',
                  '....UNDER..................',
                  '.................LAUND.....',
                  '..........FLOOR....................',
                  '........................MANOR'
                  ]


                for i in 0..set_of_partials.length - 1
                  if (partial == set_of_partials[i])
                    mySolution = set_of_plaintext[i]
                  end
                end
            # --- End solution code --- #

            puts "\n\nmySolution is (" + mySolution + ")\n\n"
            correct = ContestsHelper::Dojo6.verify_level0(
              params[:solution], mySolution
            )
        elsif level == '2'
            #RSA bruteforce
            d = -1
            ciphertext = params[:rsa_ciphertext].to_i
            publicKey = params[:publicKey].to_i
            n = params[:exponentN].to_i
       



            #Real solution: use primes as the first 14000 primes (~1 minute runtime)
            #Fast solution for Rails site: use the hardcoded list of primes
            primes = [98519, 98893, 98899, 98963, 99181, 99487, 99661, 99787, 99923, 100003, 100129, 100313, 100363, 100549, 100613, 100799, 100957, 100987, 101113, 101267, 101293, 101501, 101513, 101627, 101723, 101929, 102001, 102061, 102161, 102229, 102337, 102503, 102607, 102811, 102871, 103001, 103123, 103319, 103483, 103549, 103651, 103801, 103967, 103991, 104089, 104161, 104239, 104323, 104417, 104579, 104729]
            #primes = Prime.first(14000)

            mySolution = ""
            primes.each do |p|
            #for p in primeLowerBound..primeUpperBound
            #if (Prime.prime?(p)) then
              primes.each do |q|
              #for q in primeLowerBound..primeUpperBound
              #if (Prime.prime?(q)) then
                if (n == p*q) then
                  puts "DBG: n = pq"
                  totient = (p-1)*(q-1)
                  g,x,y = extended_gcd(totient,publicKey)
                  if (y < 0) then
                    y = totient + y
                  end
                  d = y
                  puts "DBG IN LOOP: d is " + d.to_s
                  puts "DBG IN LOOP: ASCII ENCODED IS " + ciphertext.rosetta_mod_exp(d,n).to_s
                  mySolution = ASCII_decode(ciphertext.rosetta_mod_exp(d,n).to_s)
                  puts "DBG IN LOOP: mySolution is " + mySolution
                end
              end
              #end
            #end
            end
              puts "DBG: my solution is (" + mySolution + ") and client solution is (" + params[:solution] +")"
             correct = ContestsHelper::Dojo6.verify_level0(
              params[:solution], mySolution
            )
        end
      end


      if contest.puzzle_ident == 6
        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time
        level = params[:level]
        if time_elapsed > 120 && level < 3
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end
        msg = nil
        if level == "3" or level == "4"
          msg = params[:searches] + params[:locations]
          key = ENV['HMAC_KEY'] || "derp"
          hmac = OpenSSL::HMAC.hexdigest('sha256', msg, key)
          if hmac != session[:key]
            redirect_to contest, alert: 'Cheating detected...'
            return
          end
          session.delete :key
        end
        if time_elapsed > 180 && level >= 3
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end

        if level == '0'
          number = params[:number].to_i
          our_sum = 0
          len = (number.to_s().length)
          for digit in 0..len-1
            #count 2s in range at current digit
            a = num2s_helper(number,digit)
            our_sum = our_sum + a
          end
          solution = our_sum.to_s
          puts "\n\n" + solution + "\n\n"
          correct = ContestsHelper::Dojo6.verify_level0(
            params[:solution], solution
          )
        elsif level == '1'
          usernames = params[:usernames]
          solution = ""
          arr = usernames.split()
          arr.each_index { |i|
          test = /_|\.|\+/ =~ arr[i]
          if test != 0
            solution = solution + "Invalid\n"
          else
            test2 = /[a-z]/ =~ arr[i]
            if test2 != 1
              solution = solution + "Invalid\n"
            else
              test3 = /\W/ =~ arr[i][1..-1]
              if test3 == nil
                solution = solution + "Valid\n"
              else
                solution = solution + "Invalid\n"
              end
            end
          end

          }
          solutionParams = params[:solution].tr("\n","")
          solutionParams = solutionParams.tr("\r","")
          solution = solution.tr("\r","")
          solution = solution.tr("\n","")
          correct = ContestsHelper::Dojo6.verify_level1(
          solutionParams, solution
          )
        elsif level == '2'
          solution = ''
          clubs = params[:clubs]
          course = params[:course]
          holeCounts = []
          clubDistances = clubs.split(" ")
          clubDistances.each_index { |i|
              clubDistances[i] = clubDistances[i][2..-1]
          }
          putter = clubDistances[9].to_i
          holes = course.split()
          holes.each_index { |i|
              shots = []
              count = holes[i].to_i
              limit = count + 30
              for z in 0..limit
                shots[z] = 1000
              end
              j = 0
              k = 0
              for j in 0..limit
                if j < 30
                  if (30-j <= putter)
                    shots[j] = 1
                  elsif (30-j <= 2*putter)
                    shots[j] = 2
                  else
                    shots[j] = 3
                  end
                elsif j == 30
                  shots[j] = 0
                else
                  for k in 0..9
                    if k == 9
                      for l in 0..clubDistances[k].to_i
                        prev = j - l
                        if prev >= 0
                          if (shots[prev]>=0)
                            shots[j] = [shots[prev]+1, shots[j]].min
                          end
                        end
                      end
                    else
                      prev = j- clubDistances[k].to_i
                      if prev >=0
                        if (shots[prev] >= 0)
                          shots[j] = [shots[prev] + 1, shots[j]].min
                        end
                      end
                    end
                  end
                end
              end
              if shots[limit] == 1000
                shots[limit] = -1
              end
              solution = solution + " " + shots[limit].to_s 
            }
          solution = solution[1..-1]
          puts "\n\n" + solution + "AHHHHHHH"
          correct = ContestsHelper::Dojo6.verify_level2(
            params[:solution], solution
          )
        elsif level == '3'
          perf=0
          correct,perf = ContestsHelper::Dojo2.verify_level1(params[:searches], params[:locations], params[:solution])
        elsif level == '4'
          perf=0
          correct,perf = ContestsHelper::Dojo2.verify_level2(params[:searches], params[:locations], params[:solution])
        end
      end

      if contest.puzzle_ident == 5
        
        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time
        if time_elapsed > 180
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end

        phrase = ''
        level = params[:level]
        if level == '0'
          number = params[:number]

          phrase = ''
          File.open("lib/p0/instrfile#{number}.txt", 'r') do |f|
            f.each_line{|line| phrase = phrase + line.to_s }
          end
          contents1 = File.open("lib/p0/instrfile#{number}.txt", 'rb') { |fi| fi.read }
          phrase = phrase[0...-1]
          if phrase == params[:solution]
            puts "AHHHHHHHHHHH \n\n"
          end
          solutionA = params[:solution].tr("\n","")
          solutionA = solutionA.tr("\r","")
          contents1 = contents1.tr("\n","")
          correct = ContestsHelper::Dojo5.verify_level0(
              solutionA, contents1
            )
        end
        if level == '1'
          number = params[:number]

          contents1 = File.open("lib/p1/stackfile#{number}.txt", 'rb') { |fi| fi.read }
          phrase = phrase[0...-1]
          solutionA = params[:solution].tr("\n","")
          solutionA = solutionA.tr("\r","")
          contents1 = contents1.tr("\n","")
          correct = ContestsHelper::Dojo5.verify_level0(
              solutionA, contents1
            )
        end
        if level == '2'
          number = params[:number]

          contents1 = File.open("lib/p2/scFile#{number}.txt", 'rb') { |fi| fi.read }
          phrase = phrase[0...-1]
          solutionA = params[:solution].tr("\n","")
          solutionA = solutionA.tr("\r","")
          contents1 = contents1.tr("\n","")
          correct = ContestsHelper::Dojo5.verify_level0(
              solutionA, contents1
            )
        end
        if level == '3'
          number = params[:number]

          contents1 = File.open("lib/p3/canaryFile#{number}.txt", 'rb') { |fi| fi.read }
          phrase = phrase[0...-1]
          solutionA = params[:solution].tr("\n","")
          solutionA = solutionA.tr("\r","")
          contents1 = contents1.tr("\n","")
          correct = ContestsHelper::Dojo5.verify_level0(
              solutionA, contents1
            )
        end
        if level == '4'
          number = params[:number]

          contents1 = File.open("lib/p4/canaryFile#{number}.txt", 'rb') { |fi| fi.read }
          phrase = phrase[0...-1]
          solutionA = params[:solution].tr("\n","")
          solutionA = solutionA.tr("\r","")
          contents1 = contents1.tr("\n","")
          correct = ContestsHelper::Dojo5.verify_level0(
              solutionA, contents1
            )
        end
        if level == '5'
          number = params[:number]

          contents1 = File.open("lib/p5/canaryFile#{number}.txt", 'rb') { |fi| fi.read }
          phrase = phrase[0...-1]
          solutionA = params[:solution].tr("\n","")
          solutionA = solutionA.tr("\r","")
          contents1 = contents1.tr("\n","")
          correct = ContestsHelper::Dojo5.verify_level0(
              solutionA, contents1
            )
        end
      end
      if contest.puzzle_ident == 4
        /
        riddle = params[:riddle]
        key = ENV['HMAC_KEY'] || "derp"
        hmac = OpenSSL::HMAC.hexdigest('sha256', riddle, key)
        if hmac != session[:key]
          redirect_to contest, alert: 'Cheating detected...'
          return
        end
        session.delete :key
        /
        level = params[:level]

        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time
        if time_elapsed > 120
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end

        if level == '0'
          solution = ''
          solver = params[:riddle]
          last = nil
          counter = 0

          solver.each_byte.each do |i|
            if i == 45
              if counter != 0
                bit = 64 + counter + 1
                            counter = 0
                            solution = solution + bit.chr
                        end
                        solution = solution + '-'
                  elsif i != last && last != nil && last != 45
                        bit = 64 + counter + 1
                        counter = 0
                        solution = solution + bit.chr
                  else
              if last != 45 && last != nil
                          counter = counter + 1
              end
                  end
            last = i
          end

          bit = 64 + counter + 1
          solution = solution + bit.chr

          correct = ContestsHelper::Dojo4.verify_level0(
              params[:solution], solution
            )
        end

        if level == '1'
          
          phrase = ''
          riddle = params[:riddle]

          50.times do |i|
            solution = 0
            if (riddle[i*13] == riddle[i*13+1]) && (riddle[i*13] == riddle[i*13+2])
                solution = solution + 1
            end
            if (riddle[i*13+4] == riddle[i*13+5]) && (riddle[i*13+4] == riddle[i*13+6])
                solution = solution + 1
            end
            if (riddle[i*13+8] == riddle[i*13+9]) && (riddle[i*13+8] == riddle[i*13+10])
                solution = solution + 1
            end
            if (riddle[i*13] == riddle[i*13+4]) && (riddle[i*13] == riddle[i*13+8])
                solution = solution + 1
            end
            if (riddle[i*13+1] == riddle[i*13+5]) && (riddle[i*13+1] == riddle[i*13+9])
                solution = solution + 1
            end
            if (riddle[i*13+2] == riddle[i*13+6]) && (riddle[i*13+2] == riddle[i*13+10])
                solution = solution + 1
            end
            if (riddle[i*13] == riddle[i*13+5]) && (riddle[i*13] == riddle[i*13+10])
                solution = solution + 1
            end
            if (riddle[i*13+2] == riddle[i*13+5]) && (riddle[i*13+2] == riddle[i*13+8])
                solution = solution + 1
            end
            phrase = phrase + solution.to_s
          end

          correct = ContestsHelper::Dojo4.verify_level1(
              params[:solution], phrase
            )
        end

        phrase = ''
        if level == '2'
          number = Integer(params[:phrase])

          phrase = ''
          File.open("lib/sltn#{number}.txt", 'r') do |f|
            f.each_line{|line| phrase = phrase + line.to_s }
          end
          phrase = phrase[0...-1]
          correct = ContestsHelper::Dojo4.verify_level2(
              params[:solution], phrase
            )
        end
      elsif contest.puzzle_ident == 3
        session.delete :key

        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time

        level = params[:level]
        max_time_allowed = case level
                            when 0 then 120
                            when 1 then 120
                            when 2 then 300
                            when 3 then 600
                            else 600
                            end
        if time_elapsed > max_time_allowed
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end

        begin
          aes = OpenSSL::Cipher::Cipher.new("AES-128-CBC")
          aes.decrypt
          aes.pkcs5_keyivgen(ENV['ENC_PASS'] || "foobar",
                             ENV['ENC_SALT'] || "sodiumcl")
          our_plain =  aes.update(session[:soln].split.pack('H*'))
          our_plain << aes.final
        rescue OpenSSL::Cipher::CipherError => e
          redirect_to contest,
            alert: "Something funny happened there, try again"
          return
        ensure
          session.delete :soln
        end

        correctp = ContestsHelper::Dojo3.verify_puzzle(level.to_i,
                                                       our_plain,
                                                       params[:solution])
        if correctp
          if ENV["RAILS_ENV"] == "production"
            Pony.mail(
              :to => 'huenikad@gmail.com',
              :from => 'dojobot@hackeracademy.org',
              :subject => "#{current_user.name} has solved problem #{level} at #{Time.now}")
          end
          redirect_to contest, notice: 'Congratulations! Your solution was correct!'
          current_user.solved ||= []
          current_user.solved << ["dojo#{contest.puzzle_ident}_level#{level}", Time.now]
          current_user.save
        else
          redirect_to contest, alert: 'Sorry, your solution was incorrect'
        end
        return
      elsif contest.puzzle_ident == 2
        msg = nil
        level = params[:level]

        if level == "0"
          msg = params[:query] + params[:posts]
        elsif level == "1" or level == "2"
          msg = params[:searches] + params[:locations]
        end
        key = ENV['HMAC_KEY'] || "derp"
        hmac = OpenSSL::HMAC.hexdigest('sha256', msg, key)
        if hmac != session[:key]
          redirect_to contest, alert: 'Cheating detected...'
          return
        end
        session.delete :key

        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time
        if time_elapsed > 180
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end

        # CHECK SOLUTION

        if level == '0'
          correct = ContestsHelper::Dojo2.verify_level0(params[:posts], params[:query], params[:solution])
        elsif level == '1'
          correct,perf = ContestsHelper::Dojo2.verify_level1(params[:searches], params[:locations], params[:solution])
        elsif level == '2'
          correct,perf = ContestsHelper::Dojo2.verify_level2(params[:searches], params[:locations], params[:solution])
        end
      elsif contest.puzzle_ident == 1
        puzzle = params[:puzzle].gsub('N', "\n")
        words = params[:words].split('+')
        prob = {puzzle: puzzle, words: words}
        msg = puzzle + words.join('')
        key = ENV['HMAC_KEY'] || "derp"
        hmac = OpenSSL::HMAC.hexdigest('sha256', msg, key)
        if hmac != session[:key]
          redirect_to contest, alert: 'Cheating detected...'
          return
        end
        session.delete :key
        level = params[:level]
        time_elapsed = Time.now.to_i - session[:time]
        session.delete :time
        if time_elapsed > 120
          redirect_to contest,
            alert: "Sorry, you took too long with your answer (#{time_elapsed} seconds)"
          return
        end
        # This is rather more difficult to split up, since we need to do different
        # preprocessing to the input before we can check it

        soln = nil
        if level == '0'
          soln = params[:solution].split(/\s*,\s*/).map(&:to_i)
          if soln.length != prob[:words].length
            correct = false
          else
            correct = ContestsHelper::Dojo1.verify_level0(
              Hash[*prob[:words].sort.zip(soln).flatten], prob[:puzzle]
            )
          end
        elsif level == '1' || level == '2'
          soln = params[:solution].split(/\s*;\s*/).map do |pair|
            pair.split(/\s*,\s*/).map(&:to_i)
          end
          if soln.length != prob[:words].length
            correct = false
          else
            soln = prob[:words].sort.zip(soln)
            correct = ContestsHelper::Dojo1.verify_puzzle(level,
              soln.inject({}) {|h,e| h[e.first] = e.second; h}, prob[:puzzle]
            )
          end
        end
      end

      if correct

        if ENV["RAILS_ENV"] == "production"
          if true
            Pony.mail(
              :to => 'huenikad@gmail.com',
              :from => 'dojobot@hackeracademy.org',
              :subject => "#{current_user.name} has solved problem #{level} of dojo #{contest.puzzle_ident} at #{Time.now}")
            if perf != -1
               Pony.mail(
              :to => 'huenikad@gmail.com',
              :from => 'dojobot@hackeracademy.org',
              :subject => "#{perf.round(2)} #{current_user.name} P#{level} D#{contest.puzzle_ident} at #{Time.now}")
            end
          end
        end
        if perf != -1
          redirect_to contest, notice: "Congratulations! Your solution was good enough! #{perf.round(2)}"
        else
          redirect_to contest, notice: 'Congratulations! Your solution was correct!'
        end
        current_user.solved ||= []
        current_user.solved << ["dojo#{contest.puzzle_ident}_level#{level}", Time.now]
        current_user.save
      else
        if perf != -1
          if ENV["RAILS_ENV"] == "production"
          if true
            Pony.mail(
              :to => 'huenikad@gmail.com', 
              :from => 'dojobot@hackeracademy.org',
              :subject => "#{perf.round(2)} #{current_user.name} P#{level} at #{Time.now}")
            end
          end
          redirect_to contest, alert: "Sorry, your solution was not good enough. P=#{perf.round(2)}"
        else
          redirect_to contest, alert: 'Sorry, your solution was incorrect'
        end
      end
    end

    # GET /contests/new
    # GET /contests/new.xml
    def new
      @contest = Contest.new

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @contest }
      end
    end

    # GET /contests/1/edit
    def edit
      @contest = Contest.find(params[:id])
    end

    # POST /contests
    # POST /contests.xml
    def create
      @contest = Contest.new(params[:contest])

      respond_to do |format|
        if @contest.save
          format.html { redirect_to(@contest, :notice => 'Contest was successfully created.') }
          format.xml  { render :xml => @contest, :status => :created, :location => @contest }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @contest.errors, :status => :unprocessable_entity }
        end
      end
    end

    # PUT /contests/1
    # PUT /contests/1.xml
    def update
      @contest = Contest.find(params[:id])

      respond_to do |format|
        if @contest.update_attributes(params[:contest])
          format.html { redirect_to(@contest, :notice => 'Contest was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @contest.errors, :status => :unprocessable_entity }
        end
      end
    end

    # DELETE /contests/1
    # DELETE /contests/1.xml
    def destroy
      @contest = Contest.find(params[:id])
      @contest.destroy

      respond_to do |format|
        format.html { redirect_to(contests_url) }
        format.xml  { head :ok }
      end
    end
  end


