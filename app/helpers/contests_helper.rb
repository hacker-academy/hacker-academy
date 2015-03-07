  # To add generation and verification for a new Dojo, you should create a new
# submodule named "Dojo[N]" (e.g. Dojo1) which will contain all the code to
# generate/verify the puzzles. The module should also contain two methods with
# the following names and signatures: self.generate_puzzle(level, *args) which
# will return the new puzzle for the given level in an appopriate format, and
# self.verify_puzzle(level, *args), which will verify a puzle of the given
# level, returning true or false.

require 'digest/md5'
require 'prime'
class Date
  class << self
    def wrap_day_fraction_to_time( day_frac )
      day_fraction_to_time( day_frac )
   end
  end
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


module ContestsHelper

  def duration_between(from_date, to_date)
    hours, minutes, seconds, frac =
    Date.wrap_day_fraction_to_time( to_date - from_date )
    days = (hours/24).round
    hours = hours % 24
    return [
      pluralize(days, "day"),
      pluralize(hours, "hour"),
      pluralize(minutes, "minute"),
      pluralize(seconds, "second"),
    ].join(', ')
  end

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

  def self.generate_puzzle(dojo, level, args)
    return self.const_get(:"Dojo#{dojo}").generate_puzzle(level, *args)
  end

  def self.verify_puzzle(dojo, level, args)
    return self.const_get(:"Dojo#{dojo}").verify_puzzle(level, *args)
  end

  WORDS = Marshal.load(open('lib/words2.dump'))

  module Dojo9
    def self.generate_level0
      lines = []
      n = Random.rand(100...200)
      i = 0
      lines.push(n)
      while (i < n)
        numHours = Random.rand(30...50)
        wage = Random.rand(15.0...30.0).round(2)
        lines.push(numHours)
        lines.push(wage)
        i += 1
      end

      return {lines: lines}
    end

    def self.verify_level0(lines, their_plaintext)
      lines_array = lines.split("+")
      #Constants
      $overtimeRequirementInHours = 40
      $overtimeBonus = 1.1

      #Variables
      wage = 0.0
      hours = 0
      total = 0.0
      roundedUpPayment = 0
      numResearchers = lines_array[0].to_i
      i = 0
      while (i < numResearchers)
        hours = lines_array[i*2+1].to_i
        Rails.logger.debug "hours is: "
        Rails.logger.debug hours
        wage = lines_array[i*2+2].to_f
        #Check if the researcher worked overtime
        if (hours > $overtimeRequirementInHours)
            total += ($overtimeRequirementInHours)*wage + (hours-$overtimeRequirementInHours)*wage*$overtimeBonus
        else
            total += hours*wage
        end
        i += 1
      end
      Rails.logger.debug "Payment is:"
      Rails.logger.debug roundedUpPayment
      roundedUpPayment = total.to_i + 1
      return roundedUpPayment == their_plaintext.to_i
    end

    def self.generate_level1
      lines = []
      n = Random.rand(50...100)
      i = 0
      lines.push(n)
      while (i < n)
        num = Random.rand(5...100)
        lines.push(num)
        i += 1
      end

      return {lines: lines}
    end

    def self.verify_level1(lines, their_plaintext)
      their_solution = their_plaintext.split("\r\n")
      lines_array = lines.split("+")
      numCount = lines_array[0].to_i
      i = 0
      while (i < numCount)
        Rails.logger.debug "\n \n "
        Rails.logger.debug their_solution[i]
        Rails.logger.debug "\n \n "
        Rails.logger.debug self.oddOddEvenEvenFactors(lines_array[i+1].to_i)
        
        if (their_solution[i] != self.oddOddEvenEvenFactors(lines_array[i+1].to_i))
          return false
        end
        i += 1
      end
      return true
    end

    def self.oddOddEvenEvenFactors(num)

      numOddFactors = 0
      numEvenFactors = 0
      ee = false
      oo = false

      i = 2
      while (i<=num) do
          if (num%i == 0)
              numEvenFactors += 1
          end
          i = i + 2
      end
      if (numEvenFactors%2 == 0)
          ee = true
      end

      j = 1
      while (j<=num) do
          if (num%j == 0)
              numOddFactors += 1
          end
          j = j + 2
      end
      if (numOddFactors%2 == 1)
          oo = true
      end


      if (ee && oo)
          return "both"
      elsif (ee)
          return "even"
      elsif (oo)
          return "odd"
      else
          return "neither"
      end

    end

    $largestDistance = 0
    $largestPath = ""

    def self.generate_level2

      lines = []

      #The main variable of interest ("magnitude order" of vines)
      n = 8

      numVines = 0
      parents = 0

      for i in 1...n
        numVines = numVines + 3**i
      end

       for i in 1...(n-1)
        parents = parents + 3**i
      end

      level = 4
      for i in 1...(numVines+1)
        if (i > parents)
            lines.push("("+i.to_s+","+rand(10).to_s+","+"0"+","+"0"+","+"0"+")")
        else
            lines.push("("+i.to_s+","+rand(10).to_s+","+(level).to_s+","+(level+1).to_s+","+(level+2).to_s+")")
        end
        level += 3
      end

      return {lines: lines}
    end

    class Vine_class
      def initialize(n, le, l, c, r)
          @number = n
          @length = le
          @left = l
          @centre = c
          @right = r
      end
      attr_reader :number
      attr_reader :length
      attr_reader :left
      attr_reader :centre
      attr_reader :right
    end

    def self.verify_level2(lines, their_plaintext)
      lines_array = lines.split("+")

      their_solution = their_plaintext.split("\r\n")
      #The main variable of interest ("magnitude order" of vines)
      n = 8

      numVines = 0
      parents = 0
      vines = []

      for i in 1...n
        numVines = numVines + 3**i
      end

      k = 0
      
      while( k < numVines)
        if (lines[k] != "X")
            nums = lines_array[k].split(/[\(,\)]/)
            vines << Vine_class.new(nums[1], nums[2], nums[3], nums[4], nums[5])
        end
        k = k+1
      end

      self.swing(0,0,0,vines[0],vines,"")
      self.swing(0,0,0,vines[1],vines,"")
      self.swing(0,0,0,vines[2],vines,"")

      return $largestDistance == their_solution[0]
    end

    def self.swing(distance, pLength, p2Length, vine, vines, pathName)
      num = vine.number
      len = vine.length.to_i
      l = vine.left.to_i
      c = vine.centre.to_i
      r = vine.right.to_i
      p3Length = len + pLength + p2Length
      distance += len

      pathName = pathName + ""
      pathName = pathName + num.to_s
      pathName = pathName + "-"

      if (distance > $largestDistance)
        $largestDistance = distance
        $largestPath = pathName
      end

      if ((distance % 7) == 0)
          return
      end
      if (isPrime(distance)==0)
          return
      end
      if ((p3Length == 6) || (p3Length == 9) || (p3Length == 16))
          return
      end

      if (l == 0)

          return
      end

      swing(distance, p2Length, len, vines[l], vines, pathName)
      swing(distance, p2Length, len, vines[c], vines, pathName)
      swing(distance, p2Length, len, vines[r], vines, pathName)
    end

    def self.isPrime(num)
        value = 0
        endNum = (Math.sqrt(num)+1).to_i
        if (num < 6)
            value = 1
            return
        end
        for j in 2...endNum
            if (num%j == 0)
                value = 1
            end
        end
        return value
    end


    def self.generate_level3

      lines = []

      lines.push("4")
      lines.push("-1 -1") 
      lines.push("0 1") 
      lines.push("0 -1") 
      lines.push("1 -1") 
      lines.push("6") 
      lines.push("0 1") 
      lines.push("-1 1")
      lines.push("1 1") 
      lines.push("-1 -1") 
      lines.push("0 -1") 
      lines.push("1 -1") 
      lines.push("3") 
      lines.push("1 0") 
      lines.push("2 0") 
      lines.push("1 1") 
      lines.push("3") 
      lines.push("-1000 -1000")
      lines.push("1000 -1000")
      lines.push(" 0 1000") 
      lines.push(" 8")
      lines.push(" -2 4") 
      lines.push(" 1 3") 
      lines.push(" -3 -2") 
      lines.push(" 4 -5") 
      lines.push(" 2 0") 
      lines.push(" 0 3 ")
      lines.push(" 4 1") 
      lines.push(" -2 5")

      return {lines: lines}
    end

    def self.checkTriangle(x1,y1,x2,y2,x3,y3)

      x4 = (x1+x2+x3)/3.0
      y4 = (y1+y2+y3)/3.0
      a1 = self.cross(0,0,x1,y1,x2,y2)
      a2 = self.cross(x4,y4,x1,y1,x2,y2)
      b1 = self.cross(0,0,x2,y2,x3,y3)
      b2 = self.cross(x4,y4,x2,y2,x3,y3)
      c1 = self.cross(0,0,x3,y3,x1,y1)
      c2 = self.cross(x4,y4,x3,y3,x1,y1)

      if (self.sameSign(a1,a2) && self.sameSign(b1,b2) && self.sameSign(c1,c2))
          return 1
      else
          return 0
      end
    end

    def self.cross(x,y,x1,y1,x2,y2)
        return (((x1-x)*(y2-y))-((y1-y)*(x2-x)))
    end

    def self.sameSign(n1,n2)
        if (n1>0 && n2>0)
            return true
        elsif (n1<0 && n2<0)
            return true
        else
            return false
        end
    end

    def self.verify_level3(lines, their_plaintext)
      lines_array = lines.split("+")

      their_solution = their_plaintext.split("\r\n")
      i = 0
      j = 0
      x = []
      y = []
      input = ""
      inputCounter = 0
      numInputs = 5

      while (inputCounter < numInputs)
          numLines = lines_array[j].to_i
          j += 1
          while (i < numLines)
              input = lines_array[j]
              p = input.split(" ")
              x[i] = p[0].to_i
              y[i] = p[1].to_i
              j += 1
              i += 1
          end
          i = 0
          a = 0
          b = 1
          c = 2
          numSolutions = 0

          while (a < numLines - 2)

              while (b < numLines - 1)

                  while (c < numLines)
                      numSolutions += self.checkTriangle(x[a],y[a],x[b],y[b],x[c],y[c])
                      c += 1
                  end
                  b += 1
                  c = b + 1
              end
              a += 1
              b = a + 1
              c = b + 1
          end

          if (numSolutions != their_solution[inputCounter].to_i)
            return false
          end
          inputCounter += 1
      end
      return true
    end

    def self.generate_level4

      lines = []

      lines.push(".......#############################")
      lines.push("#######C#....##D##.................#")
      lines.push("#######.#....##.##.................#")
      lines.push("#######.......#.##.................#")
      lines.push("#######.......#.##....#............#")
      lines.push("#######............#...............#")
      lines.push("#######..#.......#.....#.........#.#")
      lines.push("#######.......#...................##")
      lines.push("#######.........#....#.#..........##")
      lines.push("#######.............#.....#........#")
      lines.push("#######.................#..........#")
      lines.push("#######.#...............#..........#")
      lines.push("######...#....#......#.............#")
      lines.push("######.........#...#...............#")
      lines.push("######........##.....#.............#")
      lines.push("######......###..#.........#.......#")
      lines.push("######......#B#....................#")
      lines.push("######......#.#...................##")
      lines.push("######......#.#....................#")
      lines.push("######........#.......#...........##")
      lines.push("######..#..........................#")
      lines.push("######......#..............#...#...#")
      lines.push("######..#..........................#")
      lines.push("#####...........#.......#..........#")
      lines.push("#####....................#..#......#")
      lines.push("#####...............#........#.....#")
      lines.push("#####....#..#......................#")
      lines.push("#####............................#.#")
      lines.push("#####...............#...........#..#")
      lines.push("#####................#.............#")
      lines.push("#####..............................#")
      lines.push("#####.......#.....................##")
      lines.push("##A.......................#......###")

      return {lines: lines}
    end

    def self.slide(x,y, lengthTravelled, map, visitedLocations, letter, letterIndex, d, startX, startY,foundLetter)

      if  (letterIndex>=$printIndex)
          print(letter[letterIndex]+"--------")
      end
      i = 0
      j = 0
      yetToSlide = true
      #Check Location

      #lengthTravelled += d

      if (visitedLocations[y][x]==true && map[y][x]!= letter[letterIndex])
          if (letterIndex >=$printIndex)
              print("!")
          end
      else
          lengthTravelled += d
      end

      if (letterIndex>=$printIndex)
          puts("FROM: " + startX.to_s + "    " + startY.to_s + "      TO: " + x.to_s + "   " + y.to_s + "   LENGTH TRAVELLED: " + lengthTravelled.to_s + "-------" + $distance.to_s)
      end

      if (lengthTravelled > 240)
          return
      end

      if ($distance > 0 && lengthTravelled > $distance)
          return
      end

      if (visitedLocations[y][x]==true && map[y][x]!= letter[letterIndex])
          return
      end
      visitedLocations[y][x] = true

      if (letterIndex >=$printIndex)
          puts(letter[letterIndex])
      end

      #if (foundLetter == true && lengthTravelled > $distance)
      #    return
      #end


      if (map[y][x] == letter[letterIndex])
          foundLetter = true
          #while (i < $height)
          #    while (j < $width)
          #        visitedLocations [i][j] = false
          #        j += 1
          #    end
          #    j = 0
          #    i += 1
          #end        name = prompt "Step"
          if (letterIndex >=$printIndex)
              print("FOUND LETTER: ")
          end
          if ($distance == 0 || lengthTravelled < $distance)
              $distance = lengthTravelled
              $letX = x
              $letY = y
          end
          return
      end



      #Check Directions
      d = 0

      #Check North
      while (y-d>=0 && yetToSlide == true)
          if (map[y-d][x] == $wall || y-d == 0)
              if (map[y-d][x] == $wall)
                  d = d - 1
              end
              yetToSlide = false
              if (letterIndex >=$printIndex)
                  print("_North_")
              end
              self.slide(x, y-d, lengthTravelled, map, visitedLocations, letter, letterIndex, d,x,y,foundLetter)
          end
          d += 1
      end
      d = 0
      yetToSlide = true

      #Check East
      while (x+d<$width && yetToSlide == true)
          if (map[y][x+d] == $wall || x+d == ($width-1))
              if (map[y][x+d] == $wall)
                  d = d - 1
              end
              yetToSlide = false
              if (letterIndex >=$printIndex)
                  print("_East _")
              end
              self.slide(x+d, y, lengthTravelled, map, visitedLocations, letter, letterIndex, d,x,y,foundLetter)
          end
          d += 1
      end
      d = 0
      yetToSlide = true

      #Check South
      while (y+d<$height && yetToSlide == true)
          if (map[y+d][x] == $wall || y+d == ($height-1))
              if (map[y+d][x] == $wall)
                  d = d - 1
              end
              yetToSlide = false
              if (letterIndex >=$printIndex)
                  print("_South_")
              end
              self.slide(x, y+d, lengthTravelled, map, visitedLocations, letter, letterIndex, d,x,y,foundLetter)
          end
          d += 1
      end
      d = 0
      yetToSlide = true

      #Check West
      while (x-d>=0 && yetToSlide == true)
          if (map[y][x-d] == $wall || x-d == 0)
              if (map[y][x-d] == $wall)
                  d = d - 1
              end
              yetToSlide = false
              if (letterIndex >=$printIndex)
                  print("_west _")
              end
              self.slide(x-d, y, lengthTravelled, map, visitedLocations, letter, letterIndex, d,x,y,foundLetter)
          end
          d += 1
      end

      visitedLocations[y][x] = false

      return
    end

    def self.verify_level4(lines, their_plaintext)
      lines_array = lines.gsub(/[+]/, '').chars.to_a

      their_solution = their_plaintext.split("\r\n")
      
      #Variables
      $width = 36 #36
      $height = 33 #33

      visitedLocations = Array.new($height) { Array.new($width) }
      travelLengths = Array.new($height) { Array.new($width) }

      $letters = []
      letters = ["A", "B", "C", "D", "E", "F"]
      letterIndex = 0
      $finalLetter = 3
      $distance = 1000
      $letterDistance = 0
      $wall = "#"
      $letX = 0
      $letY = 10
      $printIndex = 10
      lengthTravelled = 0
      x = 0
      y = 0

      #Acquire Map
      map = Array.new($height) { Array.new($width) }

      i = 0
      j = 0
      k = 0

      while (i < $height)
          while (j < $width)
              map [i][j] = lines_array[k]

              visitedLocations [i][j] = false
              travelLengths [i][j] = 1000
              j += 1
              k += 1
          end
          j = 0
          i += 1
      end

      #Find Start Location
      i = 0
      j = 0

      while (i < $height)
          while (j < $width)
              if (map [i][j] == "A")
                  x = j
                  y = i
                  $letX = x
                  $letY = y
              end
              j += 1
          end
          j = 0
          i += 1
      end

      #Begin Sliding
      letterIndex = 0
      while (letterIndex < $finalLetter)
          $distance = 0
          lengthTravelled = 0
          letterIndex += 1
          x = $letX
          y = $letY
          i = 0
          j = 0
          while (i < $height)
              while (j < $width)
                  visitedLocations [i][j] = false
                  j += 1
              end
              j = 0
              i += 1
          end
          self.slide(x,y, lengthTravelled, map, visitedLocations, letters, letterIndex, 0,x,y,false)
          #name = prompt "Step"

          Rails.logger.debug ("\n")
          Rails.logger.debug ("Letter index: ")
          Rails.logger.debug letterIndex

          Rails.logger.debug ("\n")
          Rails.logger.debug ("Our distance: ")
          Rails.logger.debug $distance.to_i

          Rails.logger.debug ("\n")
          Rails.logger.debug ("Their distance: ")
          Rails.logger.debug their_solution[letterIndex-1]

          if ($distance.to_i != their_solution[letterIndex-1].to_i)
            return false
          end
      end

      return true
    end

    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

  module Dojo8

    def self.escapeString
      outText = ""
      randNum = 1 + rand(4)

      case randNum
      when 1
        outText = "*"
      when 2
        outText = "^"
      when 3
        outText = "$"
      when 4
        outText = "?"
      end

      return outText
    end

    def self.numString
      outText = ""
      randNum = -1

      for idx in 1..(1 + rand(2)) # Add 1 to 3 chars
        randNum = rand(10) # Random from 0-9
        outText = outText + randNum.to_s
      end

      return outText
    end

    def self.capitalString
      outText = ""
      randNum = -1

      for idx in 1..(3 + rand(2)) # Add 3 to 5 chars
        randNum = 64 + 1 + rand(26) # Random from A-Z
        outText = outText + randNum.chr
      end

      return outText
    end

    def self.lowerString
      outText = ""
      randNum = -1

      for idx in 1..(1 + rand(3)) # Add 1 to 4 chars
        randNum = 96 + 1 + rand(26) # Random from a-z
        outText = outText + randNum.chr
      end

      return outText
    end

    def self.generate_level0
      return {text: 'zeroth'}
    end

    def self.verify_level0 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end
      
    def self.generate_level1
      dataType = -1     # If 1 or 2 or 3, one of: *,^,$,?
                        # If 4 or 5 or 6: number from 1-9
                        # If 7 or 8: A-Z character
                        # If 9 or 10: a-z character

      randNum = -1    # Used to determine length of substring.
      numCharacters = 0   # Number of characters outputted so far.
      outText = ""

      tempOutText = ""

      while numCharacters < 2048 do
        dataType = 1 + rand(10) # Random from 1-10

        if dataType <= 3
          tempOutText = self.escapeString()
          outText = outText + tempOutText
          numCharacters = numCharacters + tempOutText.length
        elsif dataType >= 4 and dataType <= 6
          tempOutText = self.numString()
          outText = outText + tempOutText
          numCharacters = numCharacters + tempOutText.length
        elsif dataType >= 7 and dataType <= 8
          tempOutText = self.capitalString()
          outText = outText + tempOutText
          numCharacters = numCharacters + tempOutText.length
        elsif dataType >= 9 and dataType <= 10
          tempOutText = self.lowerString()
          outText = outText + tempOutText
          numCharacters = numCharacters + tempOutText.length
        end
      end

      # Now guarantee we have at least one matching expression:
      tempOutText = ""
      tempOutText = tempOutText + (rand(2) == 0 ? "*" : "^")
      if (rand(2) == 0)
        for idx in 1..(3 + rand(3)) # Add 3 to 5 chars
          randNum = 96 + 1 + rand(26) # Random from a-z
          tempOutText = tempOutText + randNum.chr
        end
        for idx in 1..3 # Add 3 nums
          randNum = rand(10) # Random from 0-9
          tempOutText = tempOutText + randNum.to_s
        end
      else
        for idx in 1..(3 + rand(3)) # Add 3 to 5 chars
          randNum = 64 + 1 + rand(26) # Random from A-Z
          tempOutText = tempOutText + randNum.chr
        end
        for idx in 1..(1 + rand(7)) # Add 1 to 6 nums
          randNum = rand(10) # Random from 0-9
          tempOutText = tempOutText + randNum.to_s
        end 
      end
      tempOutText = tempOutText + (rand(2) == 0 ? "$" : "?")
      outText.insert(rand(2000), tempOutText)

      return {text: outText}
    end

    def self.verify_level1 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_level2
      return {text: 'second'}
    end

    def self.verify_level2 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_level3
      return {text: 'third'}
    end

    def self.verify_level3 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_level4
      return {text: 'fourth'}
    end

    def self.verify_level4 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

  module Dojo7 #nowieveniwouldcelebrate dojoN_levelM.haml


      TEXT = open('lib/corpus.txt').readlines.map(&:chomp).map(&:downcase)
      
      def self.generate_level0
        # --- Problem generate code --- #

         set_of_plaintext =[
                'NOTEPAPERWHICHHADBEENLYINGOPENUPONTHETABLEITCAMEBYTHELASTPOST',
                'HEAVYSTEPWHICHHADBEENHEARDUPONTHESTAIRSANDINTHEPASSAGEPAUSED',
                'CLIENTIFYOURMAJESTYWOULDCONDESCENDTOSTATEYOURCASEHEREMARKEDI',
                'JUSTSUCHASIHADPICTUREDFROMSHERLOCKHOLMESSUCCINCTDESCRIPTIONBUT',
                'HAVEOPENEDITMYSELFWITHTHEKEYOFTHEBOXROOMCUPBOARDHEOFTENHAD',
                'WHOWASFARGREATERTHANIWASATSTAKEANDTHATHETHREATENEDTORAISEA',
                'VEGETABLESROUNDHISNAMEISFRANCISPROSPERHESTOODSAIDHOLMESTO',
                'YOUTHENROUSEDHISANGERBYCALLINGHIMNAMESATAMOMENTWHENHEFELT',
                'SHOESWITHTHESEIJOURNEYEDDOWNTOSTREATHAMANDSAWTHATTHEYEXACTLY',
                'FELLOWWHATDOTHEPUBLICTHEGREATUNOBSERVANTPUBLICWHOCOULDHARDLY',
                'ABOUTONCEAWEEKINORDERTOSEEWHETHERANYTHINGHADTURNEDUPWHICHMIGHT'
              ]

          #TODO new set of plaintext for this
          plaintext = set_of_plaintext.sample
          #puts "ptx is " + plaintext

          pad = (0...plaintext.length).map { (65 + rand(26)).chr }.join
          #puts "pad is " + pad


          plaintext_as_array = plaintext.split(//)
          pad_as_array = pad.split(//)
          ciphertext_as_array = Array.new
          ciphertext = ""

          for i in 0..plaintext_as_array.length - 1
            n1 = plaintext_as_array[i].ord - 65
            n2 = pad_as_array[i].ord - 65
            ciphertext_as_array[i] = (n1 + n2)%26
            ciphertext_as_array[i] = ciphertext_as_array[i] + 65
            ciphertext = ciphertext + ciphertext_as_array[i].chr
          end

        # --- End problem generate code --- #
        return {ciphertext: ciphertext, otp: pad}
      end

      def self.generate_level1
        # --- Problem generate code --- #
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
                    '..F.....E......O.....T.....R......',
                    'N.....F.....U.......O......C.',
                    '.N.........H.........E....Y.....L',
                    '.....M......U.....H...E...C.....',
                    '.I.......S........A.....W......L.',
                    '..V..I.......O............B........R.',
                    'N........L..........H........I...Y',
                    '...T...E...E.....O....R....',
                    '..G.....I.......W....D....T',
                    '.....T....F.....F.....L........D...',
                    '..T..B.........T.....O......R'
                    ]

            set_of_key = ["CACTI", "MAPLE", "PINES", "SEEDY", "ROSES", "BALSA", "MOSSY", "PETAL"]

            r = Random.new
            pt_index = r.rand(0..set_of_plaintext.length - 1)

            plaintext = set_of_plaintext[pt_index]
            partial = set_of_partials[pt_index]
            key = set_of_key.sample

            plaintext_as_array = plaintext.split(//)
            key_as_array = key.split(//)
            ciphertext_as_array = Array.new
            ciphertext = ""

            for i in 0..plaintext_as_array.length - 1
              n1 = plaintext_as_array[i].ord - 65
              n2 = key_as_array[i%(key_as_array.length)].ord - 65
              ciphertext_as_array[i] = (n1 + n2)%26
              ciphertext_as_array[i] = ciphertext_as_array[i] + 65
              ciphertext = ciphertext + ciphertext_as_array[i].chr
            end
        # --- End problem generate code --- #
        puts "VIGNERE GREP HELPER"
        return {ciphertext: ciphertext, partial: partial}
      end

      def self.generate_level2
        # --- Problem generate code --- #
        #Taken on 2014-03-09 from http://rosettacode.org/wiki/Modular_exponentiation
        puts "DBG self.generate_level2"



              words = ["BEGIN", "COVER", "WOODS", "DECOY", "DUELS", "ALONE", "MAJOR", "PEEKS", "TREES", "BLUFF", "CATCH", "FALSE", "CAMPS", "CARGO", "SPIES", "SIGNS", "BRIBE", "HILLS", "RIVER", "ROADS", "TRAPS", "NORTH", "SOUTH", "BELOW", "ABOVE", "SWAMP", "SONAR", "RADAR", "RAIDS", "SCOUT"]
              primes = [98519, 98893, 98899, 98963, 99181, 99487, 99661, 99787, 99923, 100003, 100129, 100313, 100363, 100549, 100613, 100799, 100957, 100987, 101113, 101267, 101293, 101501, 101513, 101627, 101723, 101929, 102001, 102061, 102161, 102229, 102337, 102503, 102607, 102811, 102871, 103001, 103123, 103319, 103483, 103549, 103651, 103801, 103967, 103991, 104089, 104161, 104239, 104323, 104417, 104579, 104729]
              puts "DBG primes defined"

              p = -1 
              q = p

              until (p != q)
                p = primes.sample
                q = primes.sample
              end

              plaintext = words.sample #ARGV[0]
              plaintext_as_array = plaintext.split(//)
              encoded_text = ""

              for i in 0..plaintext_as_array.length - 1
                char = (plaintext_as_array[i].ord).to_s
                encoded_text = encoded_text + char
              end

              n = p*q
              totient = (p-1)*(q-1)

              primesToGenerate = 1000
              publicKey = totient + 1 #so the second condition in the 'until' below is false initially
              until ((totient.gcd(publicKey) == 1) && (publicKey < totient)) do
                publicKey = (Prime.first(primesToGenerate))[Random.rand(primesToGenerate -1)] 
              end
              puts "DBG found my publickey"

              g,x,y = extended_gcd(totient,publicKey)
              if (y < 0) then
                y = totient + y
              end

              d = y

              private1 = d  
              private2 = n

              public1 = publicKey
              public2 = n
              ciphertext = (((encoded_text.to_i)**public1)%public2)
              puts "DBG encrypted my ciphertext"

        # --- End problem generate code --- #
        puts "grep for this: in contests_helper: ciphertext as (" + ciphertext.to_s + ") publickey as (" + publicKey.to_s + ") n as (" + n.to_s + ")"

        puts "DBG about to return problem2 values"
        #return {rsa_ciphertext: "1234", publicKey: "5678", exponentN: "910"}
        return {rsa_ciphertext: ciphertext.to_s, publicKey: publicKey.to_s, exponentN: n.to_s}
        # return {ciphertext: ciphertext, partial: partial}
      end

      def self.generate_level3
        #copy+paste from dojo3

        phrase = TEXT[rand(TEXT.length), 3].join(' ').split
        key = WORDS.sample
        puts "grep for this: key is (" + key + ")"
        hint = phrase.sample
        while hint.length < 3
          hint = phrase.sample
        end
        attempts = 0
        while hint.length < key.length
          hint = phrase[rand(phrase.length), 2 + (attempts % 10)].join ' '
          attempts += 1
        end
        plain = phrase.join(' ').split(//)
        ciphered = plain.zip((key * ((plain.length / key.length) + 1)
                             ).split(//)).map do |(char, k)|
          char.ord ^ k.ord
        end.join ' '
        return {plaintext: phrase.join(' '), ciphertext: ciphered, hint: hint}
      end

      def self.generate_level4
        alphabet = ('a'..'z').to_a + [' ', '.', ',', ':', ';']
        encoding = alphabet.zip(alphabet.shuffle).inject({}) do |hsh, (k,v)|
          hsh[k] = v
          hsh
        end
        phrase = TEXT[rand(TEXT.length), 6].join(' ')
        ciphered = phrase.split(//).map {|char| encoding[char] }.join
        return {plaintext: phrase, ciphertext: ciphered}
      end

      def self.verify_level0 our_plaintext, their_plaintext
        return our_plaintext == their_plaintext
      end

      LOCATIONS = Marshal.load(open('lib/ecdojolocations.dump'))
      SALT = "nacl"

      def self.generate_puzzle(level, *args)
        return self.send("generate_level#{level}", *args)
      end

      def self.verify_puzzle(level, *args)
        return self.send("verify_level#{level}", *args)
      end
  end

  module Dojo6
    
    def self.generate_level0
      number = rand(10000..1000000)
      return {number: number.to_s}
    end

     def self.verify_level0 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_level1
      usernames= ""
      100.times {
        newUsername = ""
        temp = rand(1..10)
        if temp < 3
          newUsername = "_" + rand(36**10).to_s(36)
        elsif temp < 6
          newUsername = "." + rand(36**10).to_s(36)
        elsif temp < 8
          newUsername = "+" + rand(36**10).to_s(36)
        else
          newUsername = rand(36**10).to_s(36)
        end
        temp2 = rand(1..10)
        if temp2 > 5
          newUsername = newUsername + "_"
        end
       usernames = usernames + newUsername + " "
      }

      return {usernames: usernames}
    end

    def self.verify_level1 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_level2
      course=""
      clubs = "D:" + rand(160..260).to_s + " 2:" + rand(160..230).to_s + " 3:" + rand(150..220).to_s + " 4:" + rand(150..200).to_s + " 5:" + rand(140..190).to_s + " 6:" + rand(135..180).to_s + " 7:" + rand(125..165).to_s + " 8:" + rand(100..140).to_s + " 9:" + rand(80..120).to_s + " P:" + rand(12..24).to_s 
      18.times {course= course + rand(91..567).to_s + " "}
      return {clubs: clubs, course: course}
    end

    def self.verify_level2 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end



    LOCATIONS = Marshal.load(open('lib/ecdojolocations.dump'))
    SALT = "nacl"

    # string obfuscation functions
    # input is an array of characters

    def self.random_char
      return (rand(122-97) + 97).chr
    end

    def self.jumble_case(input)
      return input.map{|x| rand() > 0.5 ? x.upcase : x.downcase}
    end

    def self.swap_letter(input)
      x = rand(input.length-1)+1
      rmved = input.delete_at(x)
      output = input.insert(x-1, rmved)
      return output
    end

    def self.remove_letter(input)
      input.delete_at(rand(input.length))
      return input
    end

    def self.replace_letter(input)
      input[rand(input.length)] = random_char()
      return input
    end

    def self.add_letter(input)
      input.insert(rand(input.length), random_char())
      return input
    end

    def self.obfuscate(string)
      arr = string.split(//)

      arr = jumble_case(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = swap_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = remove_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = replace_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = add_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)

      return arr.join()
    end

    def self.generate_level3
      locations = LOCATIONS.sort_by{rand}[0..100]
      searches = locations.sort_by{rand} #locations.sort_by{rand}[0..100]

      hash_searches = []

      searches.each do |search|
        hash = Digest::MD5.hexdigest(search + SALT)
        search = obfuscate(search)
        hash_searches << [hash, search]
      end


      return {searches: hash_searches, locations: locations}
    end

    def self.verify_level3(searches,locations,solution)
      s = solution.split("\n").map{|x| x.strip}
      pairs = s.each_slice(2).to_a

      if searches.split('+').length != pairs.length
        return [false,-1]
      end

      total = pairs.length
      sum = 0

      pairs.each do |hash,term|
        sum += 1 if Digest::MD5.hexdigest(term + SALT) == hash
      end

      score = 1.0 * sum / total

      return [score > 0.75,score]

    end

    COMMON_WORDS = ["Bank", "Bakery", "Arts", "Court", "HQ", "North", "On", "Beach", "Community", "Garden", "Hot", "Gallery", "Dental", "on", "Golf", "Downtown", "Coffee", "Theatre", "/", "Yonge", "Gym", "Library", "Family", "In", "Car", "International", "Square", "Ave", "Express", "Shop", "Village", "Green", "Bloor", "at", "Big", "High", "Dog", "Services", "Public", "Clinic", "Studio", "Bistro", "Inc.", "Fitness", "Dr", "Health", "de", "Salon", "St.", "Casa", "A", "Church", "King", "Center", "for", "Avenue", "Spa", "East", "Store", "Home", "University", "Inn", "@", "Room", "Market", "Food", "Hotel", "Hair", "Place", "Pizza", "Dr.", "Bay", "the", "Hamilton", "Of", "West", "Grill", "City", "Station", "Building", "College", "Toronto", "Pub", "Lounge", "Hall", "And", "Office", "Canadian", "St", "Stop", "School", "Canada", "Club", "Street", "Cafe", "House", "of", "Bus", "Restaurant", "Bar", "and", "The", "Park", "Centre", "-", "&"] ;

    def self.remove_common_words(input) #array of words
      return input - COMMON_WORDS
    end

    def self.swap_words(input) #array of words
      return swap_letter(input)
    end

    def self.obfuscate_level2(string)
      words = string.split(" ")
      words = remove_common_words(words)
      words = swap_words(words) if rand < 0.1

      arr = words.join(" ").split(//)

      arr = jumble_case(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = swap_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = remove_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = replace_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = add_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)

      return arr.join()
    end

    def self.generate_level4
      locations = LOCATIONS.sort_by{rand}[0..100]
      searches = locations.sort_by{rand} #.sort_by{rand}[0..100]

      hash_searches = []

      searches.each do |search|
        hash = Digest::MD5.hexdigest(search + SALT)
        search = obfuscate_level2(search)
        hash_searches << [hash, search]
      end

      return {searches: hash_searches, locations: locations}
    end

    def self.verify_level4(searches,locations,solution)
      s = solution.split("\n").map{|x| x.strip}
      pairs = s.each_slice(2).to_a

      if searches.split('+').length != pairs.length
        return [false,-1]
      end

      total = pairs.length
      sum = 0

      pairs.each do |hash,term|
        sum += 1 if Digest::MD5.hexdigest(term + SALT) == hash
      end

      score = 1.0 * sum / total

      return [score > 0.9,score]
    end





    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

  module Dojo5

    # Level 0: 1st Stack 
    def self.generate_level0
      number = rand(1)
      riddle = Array.new

      File.open("lib/p0/binfile#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      return {riddle: riddle, number: number.to_s}
    end

    # Level 0: 1st Stack 
    def self.generate_level1
      number = rand(1)
      riddle = Array.new

      File.open("lib/p1/binfile#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      return {riddle: riddle, number: number.to_s}
    end

      # Level 0: 1st Stack 
    def self.generate_level2
      number = rand(49)
      riddle = Array.new

      File.open("lib/p2/binfile#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      return {riddle: riddle, number: number.to_s}
    end

      # Level 0: 1st Stack 
    def self.generate_level3
      number = rand(49)
      riddle = Array.new
      stack1 = Array.new
      File.open("lib/p3/binfile#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      File.open("lib/p3/stackfile#{number.to_s}.txt", 'r') do |g|
        g.each_line{|line| stack1.push(line) }
      end

      return {riddle: riddle, number: number.to_s, stackfile: stack1}
    end

      # Level 0: 1st Stack 
    def self.generate_level4
      number = rand(49)
      riddle = Array.new
      stack1 = Array.new
      File.open("lib/p4/binfile#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      File.open("lib/p4/stackfile#{number.to_s}.txt", 'r') do |g|
        g.each_line{|line| stack1.push(line) }
      end

      return {riddle: riddle, number: number.to_s, stackfile: stack1}
    end

      # Level 0: 1st Stack 
    def self.generate_level5
      number = rand(49)
      riddle = Array.new
      stack1 = Array.new

      File.open("lib/p5/binfile#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      File.open("lib/p5/stackfile#{number.to_s}.txt", 'r') do |g|
        g.each_line{|line| stack1.push(line) }
      end

      return {riddle: riddle, number: number.to_s, stackfile: stack1}
    end

    def self.verify_level0 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end
    def self.verify_level1 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end
    def self.verify_level2 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end
    def self.verify_level3 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end
    def self.verify_level4 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end
    def self.verify_level5 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

  module Dojo4
    KEYS = [
              'Fifty-paces-NE-of-the-strawberry-farm',
              'Ninety-feet-S-of-the-old-church',
              'One-mile-N-of-the-elementary-school',
              'Three-miles-S-of-the-creepy-circus',
              'Sixty-paces-SW-of-brand-new-wheat-mill',
              'Five-miles-E-of-the-stinky-rubber-factory',
              'Ninety-silly-walks-S-of-the-Ministry',
              'Just-under-the-abandoned-bridge',
              'Right-behind-the-new-laundromat',
              'On-the-third-floor-of-the-tallest-building',
              'In-the-basement-of-the-Mayors-manor'
            ]

    # Level 0: 1st Tic Tac Toe Cipher
    def self.generate_level0
      phrase = KEYS[rand(KEYS.length)].upcase

      bit = 'X'
      riddle = ''

      phrase.each_byte.each do |i|
        if i == 45
          riddle = riddle + '-'
        else
          quant = i - 64
          riddle = riddle + (bit * quant)
          if bit == 'X'
            bit = 'O'
          else bit = 'X'
          end
        end
      end

      return {riddle: riddle, phrase: ''}
    end

    def self.verify_level0 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    KEYS1 = "XO"
    KEYS2 = Array.new
    # Level 1: 2nd Tic Tac Toe Cipher
    KEYS2[0] = ['OXX', 'XOO', 'OOX', '']
    KEYS2[1] = ['OOX', 'OXO', 'XOO', '']
    KEYS2[2] = ['XOX', 'OXO', 'XOX', '']
    KEYS2[3] = ['XXX', 'OOO', 'OOO', '']
    KEYS2[4] = ['XXX', 'XXO', 'XXO', '']
    KEYS2[5] = ['XXX', 'OXO', 'XXX', '']
    KEYS2[8] = ['XXX', 'XXX', 'XXX', '']
    def self.generate_level1
      riddle = Array.new
      map = "0123458"
      phrase = ''

      50.times do |a|

        num = map[rand(map.length)]
        phrase = phrase + num
        4.times do |k|
          riddle.push(KEYS2[Integer(num)][k])
        end

        

        /
        3.times do |b|
          line = ''
          3.times do |c|
            line = line + KEYS1[rand(KEYS1.length)]
          end
          riddle.push(line)
        end
        riddle.push('')
        /
      end

      phrase = ''
      50.times do |i|
        solution = 0
        3.times do |j|
          if (riddle[i*4+j][0] == riddle[i*4+j][1]) && (riddle[i*4+j][0] == riddle[i*4+j][2])
            solution = solution + 1
          end
          if (riddle[i*4+0][j] == riddle[i*4+1][j]) && (riddle[i*4+0][j] == riddle[i*4+2][j])
            solution = solution + 1
          end
        end
        if (riddle[i*4+0][0] == riddle[i*4+1][1]) && (riddle[i*4+0][0] == riddle[i*4+2][2])
          solution = solution + 1
        end
        if (riddle[i*4+0][2] == riddle[i*4+1][1]) && (riddle[i*4+0][2] == riddle[i*4+2][0])
          solution = solution + 1
        end
        phrase = phrase + solution.to_s
      end

      return {riddle: riddle, phrase: ''}
    end

    def self.verify_level1 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_level2
      number = rand(19)
      riddle = Array.new
      maze_names =  [
        'OOOOXXOO',
        'XOOOXXXX',
        'OOOXXOOX',
        'OOOOXXXX',
        'XOOOXOOO',
        'OXXXOOXX',
        'XOXXXXOX',
        'OXXOXXOX',
        'OOXOOOOX',
        'OXOOXXOO',
        'OXXOXXXX',
        'XXOXOOXO',
        'OXXOXXOO',
        'XOXOXXOX',
        'OXOXXXOX',
        'XOXOOOXO',
        'XXOOXXOX',
        'OXXOXXXO',
        'OXOOOXOO',
        'OXXOOXXX'
        ]

      File.open("lib/maze#{number.to_s}.txt", 'r') do |f|
        f.each_line{|line| riddle.push(line) }
      end

      return {riddle: riddle, phrase: number.to_s}
    end

    def self.verify_level2 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end

    def self.random_letter
      letters = "XO"
      letters[rand letters.length]
    end

    def self.random_letters num
      (1..num).collect do
        random_letter
      end
    end
  end

  module Dojo3

    TEXT = open('lib/corpus.txt').readlines.map(&:chomp).map(&:downcase)

    def self.shift_encode text, shift
      return text.split(//).map do |char|
        (((char.ord - 'a'.ord + shift) % 26) + 'a'.ord).chr
      end.join
    end

    # Level 0: Shift cipher with a given shift - spaces removed
    def self.generate_level0
      phrase = TEXT[rand(TEXT.length), 3].join.gsub(/[^a-z]/, '')
      shift = rand 26
      shifted = shift_encode phrase, shift
      return {shift: shift, ciphertext: shifted, plaintext: phrase}
    end

    def self.verify_level0 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    # Level 1: Shift cipher
    def self.generate_level1
      # Only difference is that we don't give the user the shift
      generate_level0
    end

    def self.verify_level1 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    # Level 2: XOR cipher with fragment of plaintext given
    def self.generate_level2
      phrase = TEXT[rand(TEXT.length), 3].join(' ').split
      key = WORDS.sample
      hint = phrase.sample
      while hint.length < 3
        hint = phrase.sample
      end
      attempts = 0
      while hint.length < key.length
        hint = phrase[rand(phrase.length), 2 + (attempts % 10)].join ' '
        attempts += 1
      end
      plain = phrase.join(' ').split(//)
      ciphered = plain.zip((key * ((plain.length / key.length) + 1)
                           ).split(//)).map do |(char, k)|
        char.ord ^ k.ord
      end.join ' '
      puts "grep for this: in real dojo3: plaintext is " + phrase.join(' ')
      return {plaintext: phrase.join(' '), ciphertext: ciphered, hint: hint}
    end

    def self.verify_level2 our_plaintext, their_plaintext
      return our_plaintext == their_plaintext
    end

    # Level 3: Arbitrary substitution cipher
    def self.generate_level3
      alphabet = ('a'..'z').to_a + [' ', '.', ',', ':', ';']
      encoding = alphabet.zip(alphabet.shuffle).inject({}) do |hsh, (k,v)|
        hsh[k] = v
        hsh
      end
      phrase = TEXT[rand(TEXT.length), 6].join(' ')
      ciphered = phrase.split(//).map {|char| encoding[char] }.join
      return {plaintext: phrase, ciphertext: ciphered}
    end

    def self.verify_level3 our_plaintext, their_plaintext
      puts "grep for this: ours=(" + our_plaintext + "), theirs=(" + their_plaintext + ")"
      return our_plaintext == their_plaintext
    end

    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

  module Dojo2

    POSTS = Marshal.load(open('lib/ecdojoposts.dump'))
    # hash:
    # ID => [ ID (str) , DATETIME (int), MESSAGE (string) ]

    def self.generate_level0
      query = %w(guy girl drink dance shirt red the you).sample
      # select random subset of posts
      posts = POSTS.values.sort_by{rand}[0..50]
      # choose a word
      return {query: query, posts: posts}
    end

    def self.verify_level0(posts, query, soln)
      s = soln.split("\n").map{|x| x.strip}.join("+")

      times_ids = []

      posts.split('+').each do |post_id|
        if POSTS[post_id][2].downcase.include? query #TODO make this a better check
          times_ids << [POSTS[post_id][1], POSTS[post_id][0]]
        end
      end

      if times_ids.length.to_s == "0"
        actual_soln = "0"
      else
        actual_soln = [times_ids.length.to_s,times_ids.sort.map{|x| x[1]}.join("+")].join("+")
      end

      return s == actual_soln
    end

    LOCATIONS = Marshal.load(open('lib/ecdojolocations.dump'))
    SALT = "nacl"

    # string obfuscation functions
    # input is an array of characters

    def self.random_char
      return (rand(122-97) + 97).chr
    end

    def self.jumble_case(input)
      return input.map{|x| rand() > 0.5 ? x.upcase : x.downcase}
    end

    def self.swap_letter(input)
      x = rand(input.length-1)+1
      rmved = input.delete_at(x)
      output = input.insert(x-1, rmved)
      return output
    end

    def self.remove_letter(input)
      input.delete_at(rand(input.length))
      return input
    end

    def self.replace_letter(input)
      input[rand(input.length)] = random_char()
      return input
    end

    def self.add_letter(input)
      input.insert(rand(input.length), random_char())
      return input
    end

    def self.obfuscate(string)
      arr = string.split(//)

      arr = jumble_case(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = swap_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = remove_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = replace_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)
      arr = add_letter(arr) if rand < (0.1 + 0.3 * arr.length / 18)

      return arr.join()
    end

    def self.generate_level1
      locations = LOCATIONS.sort_by{rand}[0..100]
      searches = locations.sort_by{rand} #locations.sort_by{rand}[0..100]

      hash_searches = []

      searches.each do |search|
        hash = Digest::MD5.hexdigest(search + SALT)
        search = obfuscate(search)
        hash_searches << [hash, search]
      end


      return {searches: hash_searches, locations: locations}
    end

    def self.verify_level1(searches,locations,solution)
      s = solution.split("\n").map{|x| x.strip}
      pairs = s.each_slice(2).to_a

      if searches.split('+').length != pairs.length
        return [false,-1]
      end

      total = pairs.length
      sum = 0

      pairs.each do |hash,term|
        sum += 1 if Digest::MD5.hexdigest(term + SALT) == hash
      end

      score = 1.0 * sum / total

      return [score > 0.75,score]

    end

    COMMON_WORDS = ["Bank", "Bakery", "Arts", "Court", "HQ", "North", "On", "Beach", "Community", "Garden", "Hot", "Gallery", "Dental", "on", "Golf", "Downtown", "Coffee", "Theatre", "/", "Yonge", "Gym", "Library", "Family", "In", "Car", "International", "Square", "Ave", "Express", "Shop", "Village", "Green", "Bloor", "at", "Big", "High", "Dog", "Services", "Public", "Clinic", "Studio", "Bistro", "Inc.", "Fitness", "Dr", "Health", "de", "Salon", "St.", "Casa", "A", "Church", "King", "Center", "for", "Avenue", "Spa", "East", "Store", "Home", "University", "Inn", "@", "Room", "Market", "Food", "Hotel", "Hair", "Place", "Pizza", "Dr.", "Bay", "the", "Hamilton", "Of", "West", "Grill", "City", "Station", "Building", "College", "Toronto", "Pub", "Lounge", "Hall", "And", "Office", "Canadian", "St", "Stop", "School", "Canada", "Club", "Street", "Cafe", "House", "of", "Bus", "Restaurant", "Bar", "and", "The", "Park", "Centre", "-", "&"] ;

    def self.remove_common_words(input) #array of words
      return input - COMMON_WORDS
    end

    def self.swap_words(input) #array of words
      return swap_letter(input)
    end

    def self.obfuscate_level2(string)
      words = string.split(" ")
      words = remove_common_words(words)
      words = swap_words(words) if rand < 0.1

      arr = words.join(" ").split(//)

      arr = jumble_case(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = swap_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = remove_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = replace_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)
      arr = add_letter(arr) if rand < (0.2 + 0.3 * arr.length / 18)

      return arr.join()
    end

    def self.generate_level2
      locations = LOCATIONS.sort_by{rand}[0..100]
      searches = locations.sort_by{rand} #.sort_by{rand}[0..100]

      hash_searches = []

      searches.each do |search|
        hash = Digest::MD5.hexdigest(search + SALT)
        search = obfuscate_level2(search)
        hash_searches << [hash, search]
      end

      return {searches: hash_searches, locations: locations}
    end

    def self.verify_level2(searches,locations,solution)
      s = solution.split("\n").map{|x| x.strip}
      pairs = s.each_slice(2).to_a

      if searches.split('+').length != pairs.length
        return [false,-1]
      end

      total = pairs.length
      sum = 0

      pairs.each do |hash,term|
        sum += 1 if Digest::MD5.hexdigest(term + SALT) == hash
      end

      score = 1.0 * sum / total

      return [score > 0.9,score]
    end


    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

  module Dojo1

    def self.random_letter
      letters = "abcdefghijklmnopqrstuvwxyz"
      letters[rand letters.length]
    end

    def self.random_letters num
      (1..num).collect do
        random_letter
      end
    end

    WORDS = Marshal.load(open('lib/words2.dump'))

    def self.random_words num_words
      words = (1..num_words).collect do
        WORDS[rand WORDS.length]
      end.uniq
      while words.length < num_words
        words << WORDS[rand WORDS.length]
        words.uniq
      end
      return words
    end

    def self.generate_level0 len, num_words
      words = random_words num_words
      text = words.map {|word| if rand > 0.75 then word.reverse else word end }
      remaining = len - text.map(&:length).sum
      while remaining > 0
        nonce = random_letters(rand(remaining)+1)
        idx = rand text.length
        text.insert idx, nonce
        remaining = len - text.map(&:length).sum
      end
      return {words: words, puzzle: text.join('')}
    end

    def self.verify_level0 word_indices, puzzle
      word_indices.each do |wsym, loc|
        word = wsym.to_s
        if puzzle[loc..loc+word.length-1] == word
          next
        end

        start = loc-word.length+1
        if (start >= 0) and (puzzle[start..loc] == word.reverse)
          next
        end

        return false
      end

      return true
    end

    def self.generate_level1 len, num_words
      words = random_words num_words
      text = Array.new(len, nil)
      text.map! {|x| Array.new(len, nil)}
      words.each do |word|
        row, col = rand(len), rand(len)
        fwd = rand > 0.5
        horiz = rand > 0.5
        if horiz
          while (col + word.length >= len or
                 text[row][col..col+word.length-1].any? {|x| !x.nil? })
            row, col = rand(len), rand(len)
          end
          if fwd
            text[row][col..col+word.length-1] = word.split //
          else
            text[row][col..col+word.length-1] = word.reverse.split //
          end
        else
          while (row + word.length >= len or
                 text[row..row+word.length-1].map{|r| r[col]}.any? {|x| !x.nil? })
            row, col = rand(len), rand(len)
          end
          chars = []
          if fwd
            chars = word.reverse.split //
          else
            chars = word.split //
          end
          text[row..row+word.length-1].map!{|r| r[col] = chars.pop}
        end
      end
      text.each_index do |row|
        text[row].each_index do |col|
          if text[row][col].nil?
            text[row][col] = random_letter
          end
        end
      end
      return {words: words, puzzle: text.map{|row| row.join ''}.join("\n") }
    end

    def self.verify_level1 word_indices, puzzle_chars
      puzzle = puzzle_chars.split /\n/
      word_indices.each do |wsym, loc|
        word = wsym.to_s
        row, col = loc

        puzzle_row = puzzle[row]
        if puzzle_row[col..col+word.length-1] == word
          next
        else
          Rails.logger.debug("#{word} != #{puzzle_row[col..col+word.length-1]}")
        end

        horiz_start = col-word.length+1
        if (horiz_start >= 0) and (puzzle_row[horiz_start..col] == word.reverse)
          next
        else
          Rails.logger.debug("#{word} != #{puzzle_row[horiz_start..col]}")
        end

        puzzle_col = puzzle.map {|r| r[col]}
        if puzzle_col[row..row+word.length-1].join('') == word
          next
        else
          Rails.logger.debug("#{word} != #{puzzle_col[row..row+word.length-1].join('')}")
        end

        vert_start = row-word.length+1
        if (vert_start >= 0) and (puzzle_col[vert_start..row].join('') == word.reverse)
          next
        else
          Rails.logger.debug("#{word} != #{puzzle_col[vert_start..row].join('')}")
        end

        return false
      end
      return true
    end

    def self.generate_level2 len, num_words
      words = random_words num_words
      text = Array.new(len, nil)
      text.map! {|x| Array.new(len, nil)}
      words.each do |orig_word|
        word = orig_word.clone
        word[rand word.length] = random_letter
        row, col = rand(len), rand(len)
        fwd = rand > 0.5
        horiz = rand > 0.5
        if horiz
          while (col + word.length >= len or
                 text[row][col..col+word.length-1].any? {|x| !x.nil? })
            row, col = rand(len), rand(len)
          end
          if fwd
            text[row][col..col+word.length-1] = word.split //
          else
            text[row][col..col+word.length-1] = word.reverse.split //
          end
        else
          while (row + word.length >= len or
                 text[row..row+word.length-1].map{|r| r[col]}.any? {|x| !x.nil? })
            row, col = rand(len), rand(len)
          end
          chars = []
          if fwd
            chars = word.reverse.split //
          else
            chars = word.split //
          end
          text[row..row+word.length-1].map!{|r| r[col] = chars.pop}
        end
      end
      text.each_index do |row|
        text[row].each_index do |col|
          if text[row][col].nil?
            text[row][col] = random_letter
          end
        end
      end
      return {words: words, puzzle: text.map{|row| row.join ''}.join("\n") }
    end

    def self.off_by_one? word1, word2
      if word1 == word2
        return true
      end

      errors = 0
      len = word1.length > word2.length ? word1.length : word2.length
      (0..len).each do |i|
        if word1[i] != word2[i]
          if errors >= 1
            return false
          else
            errors += 1
          end
        end
      end
      return true
    end

    def self.verify_level2 word_indices, puzzle_chars
      puzzle = puzzle_chars.split /\n/
      word_indices.each do |wsym, loc|
        word = wsym.to_s
        row, col = loc

        puzzle_row = puzzle[row]
        if off_by_one? puzzle_row[col..col+word.length-1], word
          next
        end

        horiz_start = col-word.length+1
        if ((horiz_start >= 0) and
            (off_by_one? puzzle_row[horiz_start..col], word.reverse))
          next
        end

        puzzle_col = puzzle.map {|r| r[col]}
        if off_by_one? puzzle_col[row..row+word.length-1].join(''), word
          next
        end

        vert_start = row-word.length+1
        if ((vert_start >= 0) and
            (off_by_one? puzzle_col[vert_start..row].join(''), word.reverse))
          next
        end

        return false
      end
      return true
    end

    def self.generate_puzzle(level, *args)
      return self.send("generate_level#{level}", *args)
    end

    def self.verify_puzzle(level, *args)
      return self.send("verify_level#{level}", *args)
    end
  end

end




