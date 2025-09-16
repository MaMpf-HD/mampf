# SearchController
class SearchController < ApplicationController
  authorize_resource class: false

  before_action :set_search_string, only: [:index]
  before_action :sanitize_search_string, only: [:index]

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
        redirect_back fallback_location: root_path,
                      alert: I18n.t("controllers.search_term_short")
        false
      end
    end
end
