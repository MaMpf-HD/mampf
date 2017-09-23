class LecturesController < ApplicationController
  before_action :set_lecture, only: [:show, :edit, :update]
  authorize_resource

  def show
  end

  def index
    @lectures = Lecture.all
  end

  def edit
  end

  def update
    @course_id = lecture_params[:course_id].to_i
    course = Course.find_by_id(@course_id)
    @lecture.update(course: course)
    redirect_to lecture_path, notice: 'Lecture successfully updated'
  end


  # Use callbacks to share common setup or constraints between actions.
  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    if !@lecture.present?
      redirect_to :root, alert: 'Lecture with requested id was not found.'
    end
  end

  def lecture_params
    params.fetch(:lecture, {})
  end

end
