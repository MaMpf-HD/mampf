# SearchController
class SearchController < ApplicationController
  authorize_resource class: false
  before_action :check_for_consent

  rescue_from ActionController::ParameterMissing do |_exception|
    redirect_back_or_to root_path, alert: I18n.t("controllers.no_search_term")
  end

  def current_ability
    @current_ability ||= SearchAbility.new(current_user)
  end

  def index
    return unless set_search_string

    @tags = Tag.search_by_title(@search_string)

    # Determine which of the found tags can be seen by the user
    # (taking into account their preferences and subscribed courses).
    @filtered_tags = current_user.filter_tags(@tags)
  end

  private

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end

    def search_param
      params.expect(:search)
    end

    # Returns true on success and false on failure to allow the calling action
    # to halt execution.
    def set_search_string
      @search_string = search_param
      if @search_string.length > 1
        true
      else
        redirect_back_or_to root_path, alert: I18n.t("controllers.search_term_short")
        false
      end
    end
end
