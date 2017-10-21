# LessonsController
class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show]
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_lesson
    @lesson = Lesson.find_by_id(params[:id])
    return if @lesson.present?
    redirect_to :root, alert: 'Eine Sitzung mit der angeforderten id existiert
                               nicht.'
  end
end
