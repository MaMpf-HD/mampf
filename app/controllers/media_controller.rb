# MediaController
class MediaController < ApplicationController
  authorize_resource
  before_action :set_medium, only: [:show]
  before_action :sanitize_params
  before_action :check_for_consent

  def index
    if params[:lecture_id]
      unless Lecture.exists?(params[:lecture_id])
        redirect_to :root, alert: 'Eine Vorlesung mit der angeforderten id
                                   existiert nicht.'
        return
      end
      cookies[:current_lecture] = params[:lecture_id]
      if params[:module_id]
        unless (1..5).cover?(params[:module_id].to_i)
          redirect_to :root, alert: 'Ein Modul mit der angeforderten id existiert
                                     nicht.'
          return
        end
        available_modules = Lecture.find(params[:lecture_id]).available_modules
        unless available_modules[params[:module_id].to_i]
          redirect_to :root, alert: 'Das angeforderte Modul ist für diese
                                     Vorlesung deaktiviert.'
          return
        end
        search_results = Medium.search(params)
        search_results = search_results.reverse_order if params[:reverse]
        @media = params[:all] ? search_results : Kaminari.paginate_array(search_results).page(params[:page]).per(params[:per])
        return
      end
    end
    @media = params[:all] ? Kaminari.paginate_array(Medium.all) : Medium.page(params[:page]).per(params[:per])
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

  def sanitize_params
    params[:page] = params[:page].to_i > 0 ? params[:page].to_i : 1
    params[:all] = params[:all] == 'true'
    params[:reverse] = params[:reverse] == 'true'
    params[:per] = params[:per].to_i.in?([3,4,8,12,24]) ? params[:per].to_i : 8
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end
end
