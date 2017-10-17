class MediaController < ApplicationController
  before_action :set_medium, only: [:show]
  authorize_resource

  def index
    if params[:lecture_id]
      cookies[:current_lecture] = params[:lecture_id]
    end
    if params[:lecture_id] && params[:module_id]
      @lecture = Lecture.find_by_id(params[:lecture_id])
      case params[:module_id].to_i
      when 1
        @media = Medium.where(teachable: @lecture.lessons, sort: 'Kaviar').order(:id)
      when 2
        @media = Medium.where(teachable: @lecture, sort: 'Sesam').order(:id)
      when 3
        @media = Medium.where(teachable: @lecture, sort: 'Kiwi').order(:id)
      when 4
        @media = Medium.where(teachable: @lecture, sort: 'KeksQuiz').order(:id)
      when 5
        @media = Medium.where(teachable: @lecture, sort: 'Reste').order(:id)
      else
        redirect_to :root, alert: 'Ein Modul mit der angeforderten id existiert nicht.'
      end
    else
      @media = Medium.all
    end
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_medium
    @medium = Medium.find_by_id(params[:id])
    if !@medium.present?
      redirect_to :root, alert: 'Ein Medium mit der angeforderten id existiert nicht.'
    end
  end
end
