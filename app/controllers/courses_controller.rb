class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find_by_id(params[:id])
    if !@course.present?
      redirect_to :root, alert: 'Ein Kurs mit der angeforderten id existiert nicht.'
    end
  end
end
