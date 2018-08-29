# ChaptersController
class ChaptersController < ApplicationController
  before_action :set_chapter, only: [:show, :edit]
  authorize_resource

  def show
  end

  def edit
    @section = Section.find_by_id(params[:section_id])
  end

  private

  def set_chapter
    @chapter = Chapter.find_by_id(params[:id])
    return if @chapter.present?
    redirect_to :root, alert: 'Ein Kapitel mit der angeforderten id ' \
                              'existiert nicht.'
  end
end
