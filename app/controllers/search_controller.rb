# SearchController
class SearchController < ApplicationController
  authorize_resource class: false
  before_action :check_for_consent
  before_action :set_search_string, only: [:index]
  before_action :sanitize_search_string, only: [:index]

  def current_ability
    @current_ability ||= SearchAbility.new(current_user)
  end

  def index
    search_down = @search_string.downcase
    # determine tags whose title contains the search string
    matches = Notion.all.pluck(:tag_id, :title, :aliased_tag_id)
                    .select { |x| x.second.downcase.include?(search_down) }
                    .map { |a| a.first || a.third }.uniq
    @tags = Tag.where(id: matches)
    # determine which of the found tags can be seen by the user
    # (taking into account his preferences and subscribed courses)
    @filtered_tags = current_user.filter_tags(@tags)
    return unless @tags.empty?

    # determine tags whose title is apartial match
    find_similar_tags
  end

  private

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end

    def set_search_string
      @search_string = params[:search]
    end

    # make sure the seacrh string is not blank and consists of at least
    # two letters
    def sanitize_search_string
      if @search_string.nil?
        redirect_back fallback_location: root_path,
                      alert: I18n.t("controllers.no_search_term")
        return
      end
      return if @search_string.length > 1

      redirect_back fallback_location: root_path,
                    alert: I18n.t("controllers.search_term_short")
    end

    def find_similar_tags
      @similar_tags = Tag.similar_tags(@search_string)
      @filtered_similar_tags = current_user.filter_tags(@similar_tags)
    end
end
