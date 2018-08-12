# MediaController
class MediaController < ApplicationController
  authorize_resource
  before_action :set_medium, only: [:show]
  before_action :sanitize_params
  before_action :check_for_consent

  def index
    if params[:course_id]
      unless Course.exists?(params[:course_id])
        redirect_to :root, alert: 'Eine Modul mit der angeforderten id
                                   existiert nicht.'
        return
      end
      course = Course.find(params[:course_id])
      cookies[:current_course] = params[:course_id]
      if params[:project]
        project = params[:project]
        available_food = Course.find(params[:course_id]).available_food
        unless available_food.include?(project)
          redirect_to :root, alert: 'Ein solches MaMpf-Teilprojekt existiert ' \
                                    'für dieses Modul nicht.'
          return
        end
      end
      search_results = Medium.search(course.primary_lecture(current_user),params)
      search_results = search_results.reverse if params[:reverse]
      @media = params[:all] ? Kaminari.paginate_array(search_results) : Kaminari.paginate_array(search_results).page(params[:page]).per(params[:per])
      return
    end
    redirect_to :root
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
