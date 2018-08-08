# CoursesController
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  authorize_resource

  def show
    cookies[:current_course] = params[:id]
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Kurs mit der angeforderten id existiert
                               nicht.'
  end
end
