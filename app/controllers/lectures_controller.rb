# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, only: [:edit, :update, :destroy, :inspect,
                                     :update_teacher, :update_editors]
  authorize_resource
  before_action :check_for_consent

  def index
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
    redirect_to administration_path if @lecture.valid?
    @errors = @lecture.errors
  end

  def destroy
    @lecture.destroy
    redirect_to administration_path
  end

  def update_teacher
    @teacher_selection = (User.select_editors_hash -
                          [{ text: @lecture.teacher.info,
                           value: @lecture.teacher.id }]).to_json
  end

  def update_editors
    @editor_selection = (User.select_editors_hash -
      @lecture.course.editors.map { |e| { text: e.info, value: e.id } } -
      @lecture.editors.map { |e| { text: e.info, value: e.id } }).to_json
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
