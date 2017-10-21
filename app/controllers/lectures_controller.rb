# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, only: [:show]
  authorize_resource

  def show
    cookies[:current_lecture] = params[:id]
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    return if @lecture.present?
    redirect_to :root, alert: 'Eine Vorlesung mit der angeforderten id existiert
                               nicht.'
  end
end
