class LecturesController < ApplicationController
  before_action :set_lecture, only: [:show]
  authorize_resource

  def show
    cookies[:current_lecture] = params[:id]
  end

  def index
    @lectures = Lecture.all
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    if !@lecture.present?
      redirect_to :root, alert: 'Lecture with requested id was not found.'
    end
  end

end
