class TeachersController < ApplicationController
  before_action :set_teacher, only: [:show, :edit, :update]
  authorize_resource

  def show
  end

  def index
    @teachers = Teacher.all
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_teacher
    @teacher = Teacher.find_by_id(params[:id])
    if !@teacher.present?
      redirect_to :root, alert: 'Ein Dozent mit der angeforderten id existiert nicht.'
    end
  end

end
