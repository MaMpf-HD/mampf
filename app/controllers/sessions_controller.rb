class SessionsController < Devise::SessionsController

  # emove devise's flash message for succesful sign_in
  def create
    super
    flash.clear
  end
end