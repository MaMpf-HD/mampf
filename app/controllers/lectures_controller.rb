# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, only: [:edit, :update, :destroy, :inspect]
  authorize_resource
  before_action :check_for_consent

  def index
    # lectures = current_user.edited_lectures_with_inheritance
    # edited_lectures = Lecture.sort_by_date(lectures).to_a
    # other_lectures = Lecture.sort_by_date(Lecture.all.to_a - lectures)
    @lectures = Kaminari.paginate_array(Lecture.sort_by_date(Lecture.all))
                        .page params[:page]
  end

  def edit
  end

  def inspect
  end

  def update
    @lecture.update(lecture_params)
    redirect_to edit_lecture_path(@lecture) if @lecture.valid?
    @errors = @lecture.errors
  end

  def new
    @lecture = Lecture.new
  end

  def create
    @lecture = Lecture.new(lecture_params)
    @lecture.save
    redirect_to lectures_path if @lecture.valid?
    @errors = @lecture.errors
  end

  def destroy
    @lecture.destroy
    redirect_to lectures_path
  end

  private

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    return if @lecture.present?
    redirect_to :root, alert: 'Eine Vorlesung mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def lecture_params
    params.require(:lecture).permit(:course_id, :term_id, :teacher_id,
                                    :start_chapter, :absolute_numbering,
                                    :start_section,
                                    editor_ids: [])
  end
end
