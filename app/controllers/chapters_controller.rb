# ChaptersController
class ChaptersController < ApplicationController
  before_action :set_chapter, only: [:show, :edit, :update, :destroy, :inspect, :list_sections]
  authorize_resource

  def show
  end

  def edit
    @section = Section.find_by_id(params[:section_id])
  end

  def update
    @chapter.update(chapter_params)
    if @chapter.valid?
      predecessor = params[:chapter][:predecessor]
      if predecessor.present?
        position = predecessor.to_i
        position -= 1 if position > @chapter.position
        @chapter.insert_at(position + 1)
      end
      redirect_to edit_lecture_path(@chapter.lecture)
      return
    end
    @errors = @chapter.errors
  end

  def create
    @chapter = Chapter.new(chapter_params)
    position = params[:chapter][:predecessor]
    if position.present?
      @chapter.insert_at(position.to_i + 1)
    else
      @chapter.save
    end
    redirect_to edit_lecture_path(@chapter.lecture) if @chapter.valid?
    @errors = @chapter.errors
  end

  def new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    @chapter = Chapter.new(lecture: @lecture)
  end

  def destroy
    lecture = @chapter.lecture
    @chapter.destroy
    redirect_to edit_lecture_path(lecture)
  end

  def inspect
  end

  def list_sections
    result = @chapter.select_sections
    render json: result
  end

  private

  def set_chapter
    @chapter = Chapter.find_by_id(params[:id])
    return if @chapter.present?
    redirect_to :root, alert: 'Ein Kapitel mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def chapter_params
    params.require(:chapter).permit(:title, :display_number, :lecture_id)
  end
end
