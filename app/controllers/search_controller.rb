# SearchController
class SearchController < ApplicationController
  def index
    @search_string = params[:search]
    if @search_string.length < 2
      redirect_back fallback_location: root_path,
                    alert: 'Dein Suchbegriff sollte aus mindestens zwei ' \
                           'Buchstaben bestehen.'
    else
      search_down = @search_string.downcase
      matches = Tag.all.select { |x| x.title.downcase.include?(search_down) }
      @tags = Tag.where(id: matches.pluck(:id))
    end
  end
end
