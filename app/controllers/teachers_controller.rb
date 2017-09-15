class TeachersController < ApplicationController
  before_action :set_teacher

  def show
  end

  def index
  end

  def edit
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_teacher
    @teacher = Teacher.find(params[:id])
  end
end
