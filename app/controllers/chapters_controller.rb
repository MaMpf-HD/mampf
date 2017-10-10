class ChaptersController < ApplicationController
  before_action :set_chapter, only: [:show]
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_chapter
    @chapter = Chapter.find_by_id(params[:id])
    if !@chapter.present?
      redirect_to :root, alert: 'Ein Kapitel mit der angeforderten id exisitiert nicht.'
    end
  end
end
