require 'net/http'

class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    email = params[:user][:email]
    g = Gibbon.new('5aa23572992b0f657957cb3e891c9d10-us5')
    g.listSubscribe(:id => 'a2855df226', :email_address => email)
    super
  end

  def update
    super
  end

end
