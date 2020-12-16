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
                                             .preload(user, [:lectures,
                                                             :edited_media,
                                                             :clickers,
                                                             edited_courses: [:editors, lectures: [:term, :teacher]],
                                                             edited_lectures: [:course, :term, :teacher],
                                                             given_lectures: [:course, :term, :teacher],
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
    # see https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
    # see https://www.rubydoc.info/github/plataformatec/devise/Devise%2FControllers%2FHelpers:after_sign_in_path_for
    stored = stored_location_for(resource_or_scope)
    if stored.present? && stored != super
      stored
    else
      start_path
    end
  end

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Mon, 01 Jan 1990 00:00:00 GMT"
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

  def strict_cookie(val)
    {
      value: val,
      same_site: "Strict"
    }
  end

  def set_locale
    I18n.locale = current_user.try(:locale) || locale_param ||
                    cookie_locale_param || I18n.default_locale
    unless user_signed_in?
      cookies[:locale] = strict_cookie(I18n.locale)
    end
  end

  def store_interaction
    return if controller_name.in?(['sessions', 'administration', 'users',
                                   'events', 'interactions', 'profile',
                                   'clickers', 'clicker_votes', 'registrations'])
    return if controller_name == 'main' && action_name == 'home'
    return if controller_name == 'tags' && action_name.in?(['fill_tag_select', 'fill_course_tags'])
    study_participant = current_user.anonymized_id if current_user.study_participant
    # as of Rack 2.0.8, the session_id is wrapped in a class of its own
    # it is not a string anymore
    # see https://github.com/rack/rack/issues/1433
    InteractionSaver.perform_async(request.session_options[:id].public_id,
                                   request.original_fullpath,
                                   request.referrer,
                                   study_participant)
  end

  def locale_param
    return unless params[:locale].in?(available_locales)
    params[:locale]
  end

  def cookie_locale_param
    return unless cookies[:locale].in?(available_locales)
    cookies[:locale]
  end

  def available_locales
    I18n.available_locales.map(&:to_s)
  end
end
