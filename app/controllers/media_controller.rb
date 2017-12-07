# MediaController
class MediaController < ApplicationController
  before_action :set_medium, only: [:show]
  before_action :sanitize_page_param
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
        @media = params[:all] ? Medium.search(params) : Medium.search(params).paginate(page: params[:page], per_page: 8)
        return
      end
    end
    @media = params[:all] ? Medium.all : Medium.all.paginate(page: params[:page], per_page: 8)
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

  def sanitize_page_param
    params[:page] = params[:page].to_i > 0 ? params[:page].to_i : 1
    params[:all] = params[:all].to_i == 1
  end
end
