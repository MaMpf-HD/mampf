# CoursesController
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  before_action :set_course_admin, only: [:edit, :update]
  authorize_resource

  def index
    if current_user.admin?
      @courses = Course.order(:title).page params[:page]
      return
    end
    @courses = current_user.edited_courses.order(:title).page params[:page]
  end

  def edit
  end

  def update
    puts params[:course]
    @course.update(course_params)
  end

  def new
    @course = Course.new(editors: [current_user])
    render :edit
  end

  def create
    @course = Course.new(course_params)
    @course.save
  end

  def show
    cookies[:current_course] = params[:id]
    @lectures = @course.subscribed_lectures_by_date(current_user)
    @front_lecture = @course.front_lecture(current_user, params[:active].to_i)
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
    redirect_to courses_path
  end

  def course_params
    params.require(:course).permit(:title, :short_title, :news, :tag_ids => [],
                                   :preceding_course_ids => [],
                                   :editor_ids => [])
  end
end
