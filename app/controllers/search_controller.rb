# SearchController
class SearchController < ApplicationController
  authorize_resource class: false
  before_action :check_for_consent
  # The search string is now set and sanitized in one place.
  before_action :set_and_sanitize_search_string, only: [:index]

  # Gracefully handle cases where the search parameter is missing entirely.
  rescue_from ActionController::ParameterMissing do |_exception|
    redirect_back fallback_location: root_path,
                  alert: I18n.t("controllers.no_search_term")
  end

  def current_ability
    @current_ability ||= SearchAbility.new(current_user)
  end

  def index
    @tags = Tag.search_by_title(@search_string)

    # Determine which of the found tags can be seen by the user
    # (taking into account their preferences and subscribed courses).
    @filtered_tags = current_user.filter_tags(@tags)
  end

  private

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end

    # Use strong parameters to require the search param. This is safer and
    # raises an exception if the parameter is missing, which we handle above.
    def search_param
      params.expect(:search)
    end

    # This single before_action now handles setting the search string and
    # validating its length.
    def set_and_sanitize_search_string
      @search_string = search_param
      return if @search_string.length > 1

      redirect_back fallback_location: root_path,
                    alert: I18n.t("controllers.search_term_short")
    end
end
