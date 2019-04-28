# CoursesController
class CoursesController < ApplicationController
  before_action :check_for_course, only: [:show]
  before_action :set_course, only: [:show, :display, :take_random_quiz,
                                    :show_random_quizzes]
  before_action :set_course_admin, only: [:edit, :update, :destroy, :inspect]
  before_action :check_if_enough_questions, only: [:show_random_quizzes,
                                                   :take_random_quiz]
  before_action :check_for_consent
  authorize_resource
  layout 'administration'

  def edit
    cookies[:edited_course] = params[:id]
  end

  def update
    @course.update(course_params)
    @errors = @course.errors
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)
    @course.save
    if @course.valid?
      # set organizational_concept to default
      set_organizational_defaults
      create_notifications
      redirect_to administration_path
      return
    end
    @errors = @course.errors
  end

  def show
    cookies[:current_course] = @course.id
    @lecture = @course.primary_lecture(current_user)
    unless @course.in?(current_user.courses) && @lecture
      cookies[:current_lecture] = nil
      render layout: 'application'
      return
    end
    @lecture = @course.primary_lecture(current_user)
    cookies[:current_lecture] = @lecture.id
    render template: 'lectures/show', layout: 'application'
  end

  def inspect
  end

  def destroy
    @course.destroy
    # destroy all notifications related to this course
    destroy_notifications
    redirect_to administration_path
  end

  def display
    render layout: 'application'
  end

  def show_random_quizzes
    render layout: 'application'
  end

  def take_random_quiz
    random_quiz = @course.create_random_quiz!
    redirect_to take_quiz_path(random_quiz)
  end

  private

  def check_for_course
    return if Course.exists?(params[:id])
    redirect_to :root, alert: 'Ein Modul mit der angeforderten id existiert ' \
                              'nicht.'
  end

  def set_course
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Modul mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def set_course_admin
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to administration_path
  end

  def course_params
    params.require(:course).permit(:title, :short_title, :organizational,
                                   :organizational_concept,
                                   tag_ids: [],
                                   preceding_course_ids: [],
                                   editor_ids: [])
  end

  # create notifications to all users about creation of new course
  def create_notifications
    notifications = []
    User.where(no_notifications: false).find_each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @course.id,
                                        notifiable_type: 'Course',
                                        action: 'create')
    end
    Notification.import notifications
  end

  # destroy all notifications related to this course
  def destroy_notifications
    Notification.where(notifiable_id: @course.id, notifiable_type: 'Course')
                .delete_all
  end

  # fill organizational_concept with default view
  def set_organizational_defaults
    @course.update(organizational_concept:
                     render_to_string(partial: 'courses/' \
                                               'organizational_default',
                                      formats: :html,
                                      layout: false))
  end

  def check_if_enough_questions
    return if @course.enough_questions?
    redirect_to :root, alert: 'Für dieses Modul gibt es keinen Test.'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end
end
