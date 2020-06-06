# ApplicationController
class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you
  # authenticate the user as `authenticate_user!` (or whatever your resource is)
  # will halt the filter chain and redirect before the location can be stored.
  before_action :authenticate_user!
  before_action :set_locale
  after_action :store_interaction, if: :user_signed_in?

  etag { current_user.try :id }

  def current_user
    unless controller_name == 'administration' &&  action_name == 'index'
      return super
    end
    @current_user ||= super.tap do |user|
      ::ActiveRecord::Associations::Preloader.new
                                             .preload(user, [:courses,
                                                             :lectures,
                                                             :edited_media,
                                                             :clickers,
                                                             edited_courses: [:editors, lectures: [:term, :teacher]],
                                                             edited_lectures: [:course, :term, :teacher],
                                                             given_lectures: [:course, :term, :teacher],
                                                             course_user_joins: [:course],
                                                             notifications: [:notifiable]])
    end
  end

  # show error message if authorization with cancancan fails
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, alert: exception.message
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to main_app.root_url,
      alert: I18n.t('controllers.session_expired')
  end

  # determine where to send the user after login
  def after_sign_in_path_for(resource_or_scope)
    # checks if user consented to DSGVO and has ever edited his/her profile
    # if profile was never edited, redirect to profil editing
    stored_location_for(resource_or_scope) || super
  end

#  def self.default_url_options(options={})
#    options.merge({ :locale => I18n.locale })
#  end

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
    if params[:locale].in?(I18n.available_locales.map(&:to_s))
      locale_param = params[:locale]
    end
    I18n.locale = current_user.try(:locale) || locale_param ||
                    cookies[:locale] || I18n.default_locale
    unless user_signed_in?
      cookies[:locale] = I18n.locale
    end
  end

  def store_interaction
    return if controller_name.in?(['sessions', 'administration', 'users',
                                   'events', 'interactions', 'profile',
                                   'clickers', 'clicker_votes', 'registrations'])
    return if controller_name == 'main' && action_name == 'home'
    return if controller_name == 'tags' && action_name.in?(['fill_tag_select', 'fill_course_tags'])
    # as of Rack 2.0.8, the session_id is wrapped in a class of its own
    # it is not a string anymore
    # see https://github.com/rack/rack/issues/1433
    InteractionSaver.perform_async(request.session_options[:id].public_id,
                                   request.original_fullpath,
                                   request.referrer)
  end
end
