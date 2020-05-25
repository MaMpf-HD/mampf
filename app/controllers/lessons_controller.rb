# LessonsController
class LessonsController < ApplicationController
  before_action :set_lesson, except: [:new, :create, :list_sections]
  authorize_resource
  layout 'administration'

  def show
    I18n.locale = @lesson.locale_with_inheritance
    render layout: 'application_no_sidebar'
  end

  def edit
    I18n.locale = @lesson.locale_with_inheritance
  end

  def new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    I18n.locale = @lecture.locale_with_inheritance
    @lesson = Lesson.new(lecture: @lecture)
    section = Section.find_by_id(params[:section_id])
    @lesson.sections << section if section
  end

  def create
    @lesson = Lesson.new(lesson_params)
    I18n.locale = @lesson.lecture.locale_with_inheritance if @lesson.lecture
    # add all tags from sections associated to this lesson
    @lesson.tags = @lesson.sections.map(&:tags).flatten
    @lesson.save
    @errors = @lesson.errors
    if @lesson.valid? && params[:commit] == t('buttons.save_and_edit')
      redirect_to edit_lesson_path(@lesson)
      return
    end
    render :update
  end

  def update
    I18n.locale = @lesson.lecture.locale_with_inheritance
    @lesson.update(lesson_params)
    @errors = @lesson.errors
    return unless @errors.blank?
    update_media_order if params[:lesson][:media_order]
    @tags_without_section = @lesson.tags_without_section
    return unless @lesson.sections.count == 1 && @tags_without_section.any?
    section = @lesson.sections.first
    section.tags << @tags_without_section
  end

  def destroy
    lecture = @lesson.lecture
    I18n.locale = lecture.locale_with_inheritance
    media = @lesson.media
    # move all of the lessons's media to the level of the lesson's lecture
    media.each do |m|
      m.update(teachable: lecture,
               description: m.description.presence ||
                              (m.title + ' (' + I18n.t('admin.lesson.destroyed') + ')'))
    end
    @lesson.destroy
    redirect_to edit_lecture_path(lecture)
  end

  def list_sections
    @sections = Section.where(id: JSON.parse(params[:section_ids]))
                       .order(:position)
  end

  def inspect
    I18n.locale = @lesson.locale_with_inheritance
  end

  private

  def set_lesson
    @lesson = Lesson.find_by_id(params[:id])
    return if @lesson.present?
    redirect_to :root, alert: I18n.t('controllers.no_lesson')
  end

  def lesson_params
    params.require(:lesson).permit(:date, :lecture_id, :start_destination,
                                   :end_destination, :details,
                                   section_ids: [],
                                   tag_ids: [])
  end

  def update_media_order
    media_order = JSON.parse(params[:lesson][:media_order]).map(&:to_i) - [0]
    return unless media_order.count == @lesson.medi.count
    Medium.acts_as_list_no_update do
      @lesson.media.each do |m|
        m.update(position: media_order.index(m.id))
      end
    end
  end
end
