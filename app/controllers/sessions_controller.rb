class SessionsController < Devise::SessionsController

  # remove devise's flash message for succesful sign_in
  def create
    super
    flash.clear
  end
end