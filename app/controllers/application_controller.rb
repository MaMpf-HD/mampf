class ApplicationController < ActionController::Base
  # TODO: Change to `prepend_view_path` once the majority of view files
  # live somewhere in app/frontend/ instead of app/views/
  append_view_path "app/frontend/"

  include Turbo::Redirection
  include Pagy::Method
  include Flash

  before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you
  # authenticate the user as `authenticate_user!` (or whatever your resource is)
  # will halt the filter chain and redirect before the location can be stored.
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :set_current_user

  include LocaleSetter

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
                        locals: { lecture: lecture })
  end

  # Helper to refresh the roster groups list via Turbo Stream
  def refresh_roster_groups_list_stream(lecture, group_type = :all)
    return nil unless lecture

    component = RosterOverviewComponent.new(lecture: lecture,
                                            group_type: group_type)
    turbo_stream.update("roster_groups_list",
                        partial: "roster/components/groups_tab",
                        locals: {
                          groups: component.groups,
                          group_type: group_type,
                          component: component
                        })
  end

  protected

    def configure_permitted_parameters
      # add additional paramters to registration
      devise_parameter_sanitizer.permit(:sign_up, keys: [:locale, :consents])
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

    # https://stackoverflow.com/a/69313330/
    def set_current_user
      Current.user = current_user
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
