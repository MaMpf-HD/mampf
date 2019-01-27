# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, only: [:edit, :update, :destroy, :inspect,
                                     :update_teacher, :update_editors,
                                     :add_forum, :lock_forum, :unlock_forum,
                                     :destroy_forum]
  authorize_resource
  before_action :check_for_consent
  layout 'administration'

  def edit
    @announcements = @lecture.announcements.order(:created_at).reverse
  end

  def inspect
    @announcements = @lecture.announcements.order(:created_at).reverse
  end

  def update
    @lecture.update(lecture_params)
    redirect_to edit_lecture_path(@lecture) if @lecture.valid?
    @errors = @lecture.errors
  end

  def new
    @lecture = Lecture.new
    @from = params[:from]
    return unless @from == 'course'
    # if new action was triggered from inside a course view, add the course
    # info to the lecture
    @lecture.course = Course.find_by_id(params[:course])
  end

  def create
    @lecture = Lecture.new(lecture_params)
    @lecture.save
    if @lecture.valid?
      create_notifications
      # depending on where the create action was trriggered from, return
      # to admin index view or edit course view
      unless params[:lecture][:from] == 'course'
        redirect_to administration_path
        return
      end
      redirect_to edit_course_path(@lecture.course)
      return
    end
    @errors = @lecture.errors
  end

  def destroy
    @lecture.destroy
    # destroy all notifications related to this lecture
    destroy_notifications
    redirect_to administration_path
  end

  # teacher selection is prepared here (in the view, it will be injected
  # as additional options for a selectize input field; therefore the subtraction
  # of the current value and the .to_json)
  def update_teacher
    @teacher_selection = (User.select_editors_hash -
                          [{ text: @lecture.teacher.info,
                             value: @lecture.teacher.id }]).to_json
  end

  # editor selection is prepared here (in the view, it will be injected
  # as additional options for a selectize input field; therefore the subtraction
  # of t he current value and the .to_json)
  def update_editors
    @editor_selection = (User.select_editors_hash -
      @lecture.course.editors.map { |e| { text: e.info, value: e.id } } -
      @lecture.editors.map { |e| { text: e.info, value: e.id } }).to_json
  end

  # add forum for this lecture
  def add_forum
    unless @lecture.forum?
      Thredded::Messageboard.create(name: @lecture.title)
    end
    redirect_to edit_lecture_path(@lecture)
  end

  # lock forum for this lecture
  def lock_forum
    @lecture.forum.update(locked: true) if @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
  end

  # unlock forum for this lecture
  def unlock_forum
    @lecture.forum.update(locked: false) if @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
  end

  # destroy forum for this lecture
  def destroy_forum
    @lecture.forum.destroy if @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
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

  # create notifications to all users about creation of new lecture
  def create_notifications
    notifications = []
    User.where(no_notifications: false).find_each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @lecture.id,
                                        notifiable_type: 'Lecture',
                                        action: 'create')
    end
    Notification.import notifications
  end

  # destroy all notifications related to this lecture
  def destroy_notifications
    Notification.where(notifiable_id: @lecture.id, notifiable_type: 'Lecture')
                .delete_all
  end
end
