class TeachersController < ApplicationController
  before_action :set_teacher, only: [:show, :edit, :update]
  authorize_resource

  def show
  end

  def index
#    authorize! :index
    @teachers = Teacher.all
  end

  def edit
#    authorize! :edit, @teacher
  end

  def update
#    authorize! :update, @teacher
    @teacher.update(teacher_params)
    redirect_to teacher_path, notice: 'Teacher successfully updated'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_teacher
    @teacher = Teacher.find_by_id(params[:id])
    if !@teacher.present?
      redirect_to :root, alert: 'Teacher with requested id was not found.'
    end
  end

  def teacher_params
    params.fetch(:teacher, {}).permit(:name, :email)
  end
end
