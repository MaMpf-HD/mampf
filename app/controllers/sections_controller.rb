# SectionController
class SectionsController < ApplicationController
  before_action :set_section, only: [:show, :reset, :update, :destroy]
  authorize_resource

  def show
  end

  def new
    @chapter = Chapter.find_by_id(params[:chapter_id])
    @section = Section.new(chapter: @chapter)
  end

  def create
    @section = Section.new(section_params)
    position = params[:section][:predecessor]
    if position.present?
      @section.insert_at(position.to_i + 1)
    else
      @section.save
    end
    if @section.valid?
      if params[:section][:from] == 'lecture'
        redirect_to edit_lecture_path(@section.lecture)
        return
      end
      redirect_to edit_chapter_path(@section.chapter)
      return
    end
    @errors = @section.errors
  end

  def destroy
    chapter = @section.chapter
    @section.destroy
    redirect_to edit_chapter_path(chapter)
  end

  def update
    @old_tags = @section.tags.to_a
    @section.update(section_params)
    update_tags if @section.valid?
    @errors = @section.errors
    redirect_to edit_chapter_path(@section.chapter, section_id: @section.id) unless @errors.present?
  end

  def list_tags
    @tags = Tag.where(id: JSON.parse(params[:tags])).sort_by(&:title)
    @id = params[:id]
  end

  def list_lessons
    @lessons = Lesson.where(id: JSON.parse(params[:lessons])).sort_by(&:date)
    @id = params[:id]
  end

  private

  def set_section
    @section = Section.find_by_id(params[:id])
    return if @section.present?
    redirect_to :root, alert: 'Ein Abschnitt mit der angeforderten id existiert
                               nicht.'
  end

  def section_params
    params.require(:section).permit(:title, :display_number, :chapter_id,
                                    tag_ids: [], lesson_ids: [])
  end

  def update_tags
    new_tags = @section.tags.to_a
    (new_tags - @old_tags).each do |t|
      if @section.lecture.course.in?(t.courses)
        next unless @section.lecture.in?(t.disabled_lectures)
        t.disabled_lectures.delete(@section.lecture)
        next
      end
      next if @section.lecture.in?(t.additional_lectures)
      t.additional_lectures << @section.lecture
    end
  end
end
