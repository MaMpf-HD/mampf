# ApplicationController
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # show error message if authorization with cancancan fails
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, alert: exception.message
  end

  # determine where to send the user after login
  def after_sign_in_path_for(*)
    # checks if user consented to DSGVO and has ever edited his/her profile
    # if profile was never edited, redirect to profil editing
    consent_profile_path
  end
end
