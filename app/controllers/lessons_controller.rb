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
  end

  def create
    @lesson = Lesson.new(lesson_params)
    I18n.locale = @lesson.lecture.locale_with_inheritance if @lesson.lecture
    # add all tags from sections associated to this lesson
    @lesson.tags = @lesson.sections.map(&:tags).flatten
    @lesson.save
    if @lesson.valid?
      redirect_or_edit
      return
    end
    @errors = @lesson.errors
    render :update
  end

  def update
    I18n.locale = @lesson.lecture.locale_with_inheritance
    @lesson.update(lesson_params)
    @errors = @lesson.errors
    return unless @errors.blank?
    @tags_without_section = @lesson.tags_without_section
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

  def postprocess_tags
    @tags_hash = params[:tags]
    @tags_hash.each do |t, section_data|
      tag = Tag.find_by_id(t)
      next unless tag
      section_data.each do |s, v|
        next if v.to_i == 0
        section = Section.find(s)
        next unless section
        if !tag.in?(section.tags)
          section.tags << tag
          section.update(tags_order: section.tags_order.push(tag.id))
        end
      end
    end
    redirect_to edit_lesson_path(@lesson)
  end

  private

  def set_lesson
    @lesson = Lesson.find_by_id(params[:id])
    return if @lesson.present?
    redirect_to :root, alert: I18n.t('controllers.no_lesson')
  end

  def lesson_params
    params.require(:lesson).permit(:date, :lecture_id, :start_destination,
                                   :end_destination,
                                   section_ids: [],
                                   tag_ids: [])
  end

  def redirect_or_edit
    if params[:commit] == t('buttons.save')
      redirect_to edit_lecture_path(@lesson.lecture)
    else
      # if user clicked 'save and edit'
      redirect_to edit_lesson_path(@lesson)
    end
  end
end
