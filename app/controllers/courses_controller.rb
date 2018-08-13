# CoursesController
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  authorize_resource

  def show
    cookies[:current_course] = params[:id]
    @lectures = @course.subscribed_lectures_by_date(current_user)
    @front_lecture = @course.front_lecture(current_user, params[:active].to_i)
  end

  private

  def set_course
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Kurs mit der angeforderten id existiert
                               nicht.'
  end
end
