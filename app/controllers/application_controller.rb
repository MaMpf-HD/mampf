class ApplicationController < ActionController::Base
  # TODO: Change to `prepend_view_path` once the majority of view files
  # live somewhere in app/frontend/ instead of app/views/
  append_view_path "app/frontend/"

  include Turbo::Redirection
  include Pagy::Method
  include Flash

  # Content types allowed to render inline in the browser. Anything else served
  # inline is downgraded so a stored user blob whose real content is HTML/SVG/etc.
  # cannot execute as our own origin (a content-sniffed text/html submission served
  # inline would run as the viewing tutor).
  INLINE_SAFE_MIME_TYPES = [
    "application/pdf", "image/png", "image/jpeg", "image/gif",
    "video/mp4", "application/zip"
  ].freeze

  before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you
  # authenticate the user as `authenticate_user!` (or whatever your resource is)
  # will halt the filter chain and redirect before the location can be stored.
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :set_current_user
  before_action :enforce_password_change

  include LocaleSetter

  helper_method :devise_locale_switch_path

  etag { current_user.try(:id) }

  def current_user
    return super unless controller_name == "administration" && action_name == "index"

    @current_user ||= super.tap do |user|
      ::ActiveRecord::Associations::Preloader.new(records: [user],
                                                  associations:
                                                    [:lectures,
                                                     :edited_media,
                                                     { edited_courses:
                                                       [:editors,
                                                        { lectures: [:term,
                                                                     :teacher] }],
                                                       edited_lectures:
                                                       [:course,
                                                        :term,
                                                        :teacher],
                                                       given_lectures:
                                                      [:course,
                                                       :term,
                                                       :teacher],
                                                       notifications:
                                                       [:notifiable] }]).call
    end
  end

  # show error message if authorization with cancancan fails
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, alert: exception.message
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to main_app.root_url,
                alert: I18n.t("controllers.session_expired")
  end

  # determine where to send the user after login
  def after_sign_in_path_for(resource_or_scope)
    # see https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
    # see https://www.rubydoc.info/github/plataformatec/devise/Devise%2FControllers%2FHelpers:after_sign_in_path_for
    if password_change_required_for?(resource_or_scope)
      session[:enforce_password_change] = true
      return edit_user_registration_path
    end

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

  # Helper to refresh the campaigns tab content via Turbo Stream
  # NOTE: This should be moved to a better place once we refactor the
  # whole streaming logic for campaigns and rosters (e.g. the StreamOrchestrator,
  # see the docs).
  def refresh_campaigns_index_stream(lecture)
    return nil unless lecture

    turbo_stream.update("campaigns_container",
                        partial: "registration/campaigns/card_body_index",
                        locals: {
                          lecture: lecture,
                          registration_section: params[:registration_section]
                        })
  end

  protected

    def configure_permitted_parameters
      # add additional paramters to registration
      devise_parameter_sanitizer.permit(:sign_up, keys: [:locale, :consents])
    end

  private

    def download_path(file)
      return file.storage.path(file.id) if file.storage.respond_to?(:path)

      file.to_io.path
    end

    def send_stored_file(file, disposition:, fallback:)
      mime_type = file.metadata["mime_type"].to_s.presence

      if disposition == "inline" && mime_type &&
         INLINE_SAFE_MIME_TYPES.exclude?(mime_type)
        if mime_type.start_with?("text/")
          mime_type = "text/plain; charset=utf-8"
        else
          disposition = "attachment"
        end
      end

      options = { disposition: disposition, filename: stored_filename(file, fallback) }
      options[:type] = mime_type if mime_type

      # Serving hygiene: never let the browser content-type-sniff a stored
      # upload (e.g. an mp4) into an executable/HTML interpretation.
      response.headers["X-Content-Type-Options"] = "nosniff"
      send_file(download_path(file), **options)
    end

    def stored_filename(file, fallback)
      filename = File.basename(file.metadata["filename"].to_s.tr("\\", "/"))

      ActiveStorage::Filename.wrap(filename.presence || fallback).sanitized
    end

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

    def enforce_password_change
      return unless user_signed_in?
      return unless current_user.password_change_required?
      return if password_change_request_allowed?

      session[:enforce_password_change] = true
      redirect_to edit_user_registration_path
    end

    def password_change_request_allowed?
      return true if controller_name == "registrations" &&
                     action_name.in?(["edit", "update"])
      return true if controller_name == "passwords"

      controller_name == "sessions" && action_name == "destroy"
    end

    def password_change_required_for?(resource_or_scope)
      resource = current_resource_from_scope(resource_or_scope)
      resource&.password_change_required?
    end

    def current_resource_from_scope(resource_or_scope)
      return resource_or_scope if resource_or_scope.respond_to?(:password_change_required?)
      return unless resource_or_scope.is_a?(Symbol)

      public_send("current_#{resource_or_scope}")
    end

    # https://stackoverflow.com/a/69313330/
    def set_current_user
      Current.user = current_user
    end

    def enqueue_consumption(medium_id, mode, sort)
      ConsumptionSaver.perform_async(medium_id, mode, sort)
    rescue StandardError => e
      Rails.logger.error("Failed to enqueue consumption " \
                         "medium_id=#{medium_id} mode=#{mode} sort=#{sort}: #{e.message}")
    end

    def devise_locale_switch_path(locale)
      case [controller_name, action_name]
      when ["registrations", "edit"], ["registrations", "update"]
        edit_user_registration_path(locale: locale)
      when ["registrations", "new"], ["registrations", "create"]
        new_user_registration_path(locale: locale)
      when ["sessions", "new"], ["sessions", "create"]
        new_user_session_path(locale: locale)
      when ["passwords", "new"], ["passwords", "create"]
        new_user_password_path(locale: locale)
      when ["passwords", "edit"], ["passwords", "update"]
        edit_user_password_path(locale: locale,
                                reset_password_token:
                                  params[:reset_password_token] ||
                                  params.dig(:user, :reset_password_token))
      when ["confirmations", "new"], ["confirmations", "create"]
        new_user_confirmation_path(locale: locale)
      else
        url_for(locale: locale)
      end
    end

    # Ensures that the current request is a Turbo Frame request.
    # If not, sets a flash message and redirects to the root path.
    #
    # Usage:
    # (1) call this method at the beginning of your action
    # > require_turbo_frame
    # > return if performed?
    #
    # OR
    #
    # (2) Use it as a before_action filter
    # > before_action :require_turbo_frame, only: [:your_action]
    def require_turbo_frame
      return if turbo_frame_request?

      flash.keep[:alert] = I18n.t("controllers.no_page")
      redirect_to root_path
    end
end
