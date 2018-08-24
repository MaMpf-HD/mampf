# CoursesController
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  before_action :set_course_admin, only: [:edit, :update, :destroy, :inspect]
  authorize_resource

  def index
    edited_courses = current_user.edited_courses.order(:title).to_a
    other_courses = Course.select { |c| !c.editors.include?(current_user) }
                          .sort_by(&:title)
    @courses = Kaminari.paginate_array(edited_courses + other_courses)
                      .page params[:page]
  end

  def edit
  end

  def update
    puts params[:course]
    @course.update(course_params)
    @errors = @course.errors unless @course.valid?
  end

  def new
    @course = Course.new(editors: [current_user])
    render :edit
  end

  def create
    @course = Course.new(course_params)
    @course.save
    @errors = @course.errors unless @course.valid?
    render :update
  end

  def show
    cookies[:current_course] = params[:id]
    @lectures = @course.subscribed_lectures_by_date(current_user)
    @front_lecture = @course.front_lecture(current_user, params[:active].to_i)
  end

  def inspect
  end

  def destroy
    @course.destroy
    redirect_to courses_path
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
