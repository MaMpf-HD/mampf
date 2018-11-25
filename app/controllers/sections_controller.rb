# SectionController
class SectionsController < ApplicationController
  before_action :set_section, except: [:new, :create]
  authorize_resource
  layout 'administration'

  def show
    render layout: 'application'
  end

  def edit
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
      redirect_to edit_lecture_path(@section.lecture)
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
    old_chapter = @section.chapter
    @section.update(section_params)
    if @section.valid?
      predecessor = params[:section][:predecessor]
      if predecessor.present?
        position = predecessor.to_i
        position -= 1 if position > @section.position && old_chapter == @section.chapter
        @section.insert_at(position + 1)
      end
      if params[:commit] == 'Speichern'
        render :edit
      else
        redirect_to edit_lecture_path(@section.chapter.lecture)
      end
      return
    end
    @errors = @section.errors
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
end
