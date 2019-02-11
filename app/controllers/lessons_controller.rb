# LessonsController
class LessonsController < ApplicationController
  before_action :set_lesson, except: [:new, :create, :list_sections]
  authorize_resource
  layout 'administration'

  def show
    render layout: 'application_no_sidebar'
  end

  def edit
  end

  def new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    @lesson = Lesson.new(lecture: @lecture)
  end

  def create
    @lesson = Lesson.new(lesson_params)
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
    @lesson.update(lesson_params)
    if @lesson.valid?
      if params[:commit] == 'Speichern'
        render :edit
      else
        # if user clicked 'save and back'
        redirect_to edit_lecture_path(@lesson.lecture)
      end
      return
    end
    @errors = @lesson.errors
  end

  def destroy
    lecture = @lesson.lecture
    media = @lesson.media
    # move all of the lessons's media to the level of the lesson's lecture
    media.each do |m|
      m.update(teachable: lecture,
               description: m.description.presence ||
                              (m.title + ' (Sitzung gelöscht)'))
    end
    @lesson.destroy
    redirect_to edit_lecture_path(lecture)
  end

  def list_sections
    @sections = Section.where(id: JSON.parse(params[:section_ids]))
                       .order(:position)
  end

  def inspect
  end

  private

  def set_lesson
    @lesson = Lesson.find_by_id(params[:id])
    return if @lesson.present?
    redirect_to :root, alert: 'Eine Sitzung mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def lesson_params
    params.require(:lesson).permit(:date, :lecture_id,
                                   section_ids: [],
                                   tag_ids: [])
  end

  def redirect_or_edit
    if params[:commit] == 'Speichern'
      redirect_to edit_lecture_path(@lesson.lecture)
    else
      # if user clicked 'save and edit'
      render :edit
    end
  end
end
