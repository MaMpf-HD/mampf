# CoursesController
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  before_action :set_course_admin, only: [:edit, :update, :destroy, :inspect]
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
    create_notifications
    redirect_to administration_path if @course.valid?
    @errors = @course.errors
  end

  def show
    @course = Course.includes(lectures: [:teacher, :term, :chapters])
                    .find_by_id(params[:id])
    # id of the current course is stored in a cookie
    # the cookie is used to keep track of the course in the course dropdown
    cookies[:current_course] = params[:id]
    @lectures = @course.subscribed_lectures_by_date(current_user)
    # determine which lecture gets the top position in the lecture carousel
    # and update lecture cookie correspondingly
    @front_lecture = @course.front_lecture(current_user, params[:active].to_i)
    cookies[:current_lecture] = @front_lecture&.id
    render layout: 'application'
  end

  def inspect
  end

  def destroy
    @course.destroy
    # destroy all notifications related to this course
    destroy_notifications
    redirect_to administration_path
  end

  private

  def set_course
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Kurs mit der angeforderten id existiert ' \
                              'nicht.'
  end

  def set_course_admin
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to administration_path
  end

  def course_params
    params.require(:course).permit(:title, :short_title,
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
end
