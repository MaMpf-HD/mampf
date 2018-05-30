# ApplicationController
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, alert: exception.message
  end

  def configure_permitted_parameters
    update_attrs = [:password, :password_confirmation, :current_password,
                    :consents]
    devise_parameter_sanitizer.permit :account_update, keys: update_attrs
  end

  def after_sign_in_path_for(resource)
    consent_profile_path
  end
end
