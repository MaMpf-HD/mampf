# SectionController
class SectionsController < ApplicationController
  before_action :set_section, except: [:new, :create]
  authorize_resource except: [:new, :create]
  layout "administration"

  def current_ability
    @current_ability ||= SectionAbility.new(current_user)
  end

  def show
    I18n.locale = @section.lecture.locale_with_inheritance
    render layout: "application_no_sidebar"
  end

  def new
    @chapter = Chapter.find_by_id(params[:chapter_id])
    @section = Section.new(chapter: @chapter)
    authorize! :new, @section
    I18n.locale = @section.lecture.locale_with_inheritance
  end

  def edit
    I18n.locale = @section.lecture.locale_with_inheritance
  end

  def create
    @section = Section.new(section_params)
    authorize! :create, @section
    insert_or_save
    @errors = @section.errors
  end

  def update
    I18n.locale = @section.lecture.locale_with_inheritance
    @old_chapter = @section.chapter
    @section.update(section_params)
    if @section.valid?
      update_position
      update_tags_order
      redirect_to edit_section_path(@section)
      return
    end
    @errors = @section.errors
  end

  def destroy
    @lecture = @section.lecture
    @section.destroy
    redirect_to edit_lecture_path(@lecture)
  end

  def display
    I18n.locale = @section.lecture.locale_with_inheritance
  end

  private

    def set_section
      @section = Section.find_by_id(params[:id])
      return if @section.present?

      redirect_to :root, alert: I18n.t("controllers.no_section")
    end

    def section_params
      params.require(:section).permit(:title, :display_number, :chapter_id,
                                      :details, :hidden,
                                      tag_ids: [], lesson_ids: [])
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
      position -= 1 if position > @section.position && @old_chapter == @section.chapter
      @section.insert_at(position + 1)
    end

    def update_tags_order
      tags_order = params[:section][:tag_ids].map(&:to_i) - [0]
      SectionTagJoin.acts_as_list_no_update do
        @section.section_tag_joins.each do |st|
          st.update(tag_position: tags_order.index(st.tag_id))
        end
      end
    end
end
