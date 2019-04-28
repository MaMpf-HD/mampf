# SectionController
class SectionsController < ApplicationController
  before_action :set_section, except: [:new, :create]
  authorize_resource
  layout 'administration'

  def show
    render layout: 'application_no_sidebar'
  end

  def edit
  end

  def new
    @chapter = Chapter.find_by_id(params[:chapter_id])
    @section = Section.new(chapter: @chapter)
  end

  def create
    @section = Section.new(section_params)
    insert_or_save
    if @section.valid?
      redirect_to edit_lecture_path(@section.lecture)
      return
    end
    @errors = @section.errors
  end

  def destroy
    @lecture = @section.lecture
    @section.destroy
    redirect_to edit_lecture_path(@lecture)
  end

  def update
    @old_chapter = @section.chapter
    @section.update(section_params)
    if @section.valid?
      update_position
      update_tags_order
      if params[:commit] == 'Speichern'
        render :edit
      else
        redirect_to edit_lecture_path(@section.chapter.lecture)
      end
      return
    end
    @errors = @section.errors
  end

  def display
  end

  private

  def set_section
    @section = Section.find_by_id(params[:id])
    return if @section.present?
    redirect_to :root, alert: 'Ein Abschnitt mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def section_params
    params.require(:section).permit(:title, :display_number, :chapter_id,
                                    :hidden, tag_ids: [], lesson_ids: [])
  end

  # inserts the section in the correct position if predecessor is given,
  # otherwise just saves
  def insert_or_save
    position = params[:section][:predecessor]
    if position.present?
      @section.insert_at(position.to_i + 1)
    else
      @section.save
    end
  end

  # updates the position of the section if predecessor is given
  def update_position
    predecessor = params[:section][:predecessor]
    return unless predecessor.present?
    position = predecessor.to_i
    if position > @section.position && @old_chapter == @section.chapter
      position -= 1
    end
    @section.insert_at(position + 1)
  end

  def update_tags_order
    tags_order = params[:section][:tag_ids].map(&:to_i) - [0]
    tags_order
    @section.update(tags_order: tags_order)
  end
end
