# ApplicationController
class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you
  # authenticate the user as `authenticate_user!` (or whatever your resource is)
  # will halt the filter chain and redirect before the location can be stored.
  before_action :authenticate_user!
  before_action :set_locale

  # show error message if authorization with cancancan fails
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, alert: exception.message
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to main_app.root_url,
      alert: "Deine Sitzung ist abgelaufen. Bitte melde Dich wieder an."
  end

  # determine where to send the user after login
  def after_sign_in_path_for(resource_or_scope)
    # checks if user consented to DSGVO and has ever edited his/her profile
    # if profile was never edited, redirect to profil editing
    stored_location_for(resource_or_scope) || super
  end

  private

  # It's important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as
  #   Devise::SessionsController as that could cause an
  #   infinite redirect loop.
  # - The request is an Ajax request as this can lead to very
  #   unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? &&
      !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def set_locale
    I18n.locale = current_user.try(:locale) || params[:locale] || I18n.default_locale
  end
end
