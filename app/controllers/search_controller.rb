# SearchController
class SearchController < ApplicationController
  before_action :check_for_consent
  before_action :set_search_string, only: [:index]
  before_action :sanitize_search_string, only: [:index]

  def index
    search_down = @search_string.downcase
    matches = Tag.all.select { |x| x.title.downcase.include?(search_down) }
    @tags = Tag.where(id: matches.pluck(:id))
    @filtered_tags = current_user.filter_tags(@tags)
    return unless @tags.empty?
    find_similar_tags
  end

  private

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def set_search_string
    @search_string = params[:search]
  end

  def sanitize_search_string
    if @search_string.nil?
      redirect_back fallback_location: root_path,
                    alert: 'Du hast eine Suche ohne Suchbegriff angefordert. ' \
                           'Das funktioniert nicht.'
      return
    end
    return if @search_string.length > 1
    redirect_back fallback_location: root_path,
                  alert: 'Dein Suchbegriff sollte aus mindestens zwei ' \
                         'Buchstaben bestehen.'
  end

  def find_similar_tags
    @similar_tags = Tag.similar_tags(@search_string)
    @filtered_similar_tags = current_user.filter_tags(@similar_tags)
  end
end
