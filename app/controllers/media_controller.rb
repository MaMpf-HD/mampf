# MediaController
class MediaController < ApplicationController
  before_action :set_medium, only: [:show]
  authorize_resource

  def index
    if params[:lecture_id]
      unless Lecture.exists?(params[:lecture_id])
        redirect_to :root, alert: 'Eine Vorlesung mit der angeforderten id
                                   existiert nicht.'
        return
      end
      cookies[:current_lecture] = params[:lecture_id] if params[:lecture_id]
      if params[:lecture_id]
        unless (1..5).cover?(params[:module_id].to_i)
          redirect_to :root, alert: 'Ein Modul mit der angeforderten id existiert
                                   nicht.'
          return
        end
        @media = Medium.search(params)
        return
      end
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
