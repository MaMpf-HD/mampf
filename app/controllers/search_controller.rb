# SearchController
class SearchController < ApplicationController
  authorize_resource class: false
  before_action :check_for_consent
  layout "application_no_sidebar"

  def current_ability
    @current_ability ||= SearchAbility.new(current_user)
  end

  def index
    @search_string = params.permit(:search)[:search] if turbo_frame_request?

    if @search_string.present?
      if @search_string.length > 1
        @tags = Tag.search_by_title(@search_string)

        # Determine which of the found tags can be seen by the user
        # (taking into account their preferences and subscribed courses).
        @filtered_tags = current_user.filter_tags(@tags)
      else
        @search_too_short = true
      end
    end

    render partial: "tag_search_frame" if turbo_frame_request?
  end

  private

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end
end
