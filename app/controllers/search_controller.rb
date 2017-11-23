class SearchController < ApplicationController
  def index
    @search_string = params[:search]
    if @search_string.length < 2 then
      redirect_back fallback_location: root_path, alert: 'Dein Suchbegriff sollte aus mindestens zwei Buchstaben bestehen.'
    else
      @tags = Tag.where(id: Tag.all.select {|x| x.title.downcase.include?(@search_string.downcase) }
                             .pluck(:id))
    end
  end
end
