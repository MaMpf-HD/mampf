# ChaptersController
class ChaptersController < ApplicationController
  before_action :set_chapter, only: [:show, :edit, :update]
  authorize_resource

  def show
  end

  def edit
    @section = Section.find_by_id(params[:section_id])
  end

  def update
    @chapter.update(chapter_params)
    @errors = @chapter.errors
  end

  private

  def set_chapter
    @chapter = Chapter.find_by_id(params[:id])
    return if @chapter.present?
    redirect_to :root, alert: 'Ein Kapitel mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def chapter_params
    params.require(:chapter).permit(:title, :display_number)
  end
end
