# SearchController
class SearchController < ApplicationController
  before_action :check_for_consent

  def index
    @search_string = params[:search]
    if @search_string.nil?
      redirect_back fallback_location: root_path,
                    alert: 'Du hast eine Suche ohne Suchbegriff angefordert. ' \
                           'Das funktioniert nicht.'
      return
    end
    if @search_string.length < 2
      redirect_back fallback_location: root_path,
                    alert: 'Dein Suchbegriff sollte aus mindestens zwei ' \
                           'Buchstaben bestehen.'
    else
      search_down = @search_string.downcase
      matches = Tag.all.select { |x| x.title.downcase.include?(search_down) }
      @tags = Tag.where(id: matches.pluck(:id))
      @filtered_tags = current_user.filter_tags(@tags)
      if @tags.empty?
        @similar_tags = Tag.similar_tags(@search_string)
        @filtered_similar_tags = current_user.filter_tags(@similar_tags)
      end
    end
  end

  private

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end
end
