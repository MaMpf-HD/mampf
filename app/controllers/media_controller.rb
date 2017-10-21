# MediaController
class MediaController < ApplicationController
  before_action :set_medium, only: [:show]
  authorize_resource

  def index
    cookies[:current_lecture] = params[:lecture_id] if params[:lecture_id]
    sorts = { '1' => 'Kaviar', '2' => 'Sesam', '3' => 'Kiwi', '4' => 'KeksQuiz',
              '5' => 'Reste' }
    if params[:lecture_id] && params[:module_id]
      unless (1..5).cover?(params[:module_id].to_i)
        redirect_to :root, alert: 'Ein Modul mit der angeforderten id existiert
                                   nicht.'
        return
      end
      @lecture = Lecture.find_by_id(params[:lecture_id])
      teachable = params[:module_id] == '1' ? @lecture.lessons : @lecture
      @media = Medium.where(teachable: teachable,
                            sort: sorts[params[:module_id]]).order(:id)
      return
    end
    @media = Medium.all
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_medium
    @medium = Medium.find_by_id(params[:id])
    return if @medium.present?
    redirect_to :root, alert: 'Ein Medium mit der angeforderten id existiert
                               nicht.'
  end
end
