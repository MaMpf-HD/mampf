# MediaController
class MediaController < ApplicationController
  authorize_resource
  before_action :set_medium, only: [:show]
  before_action :set_course, only: [:index]
  before_action :check_project, only: [:index]
  before_action :sanitize_params
  before_action :check_for_consent

  def index
    cookies[:current_course] = params[:course_id]
    @media = paginated_results
  end

  def catalog
    @media = Medium.all
  end

  def show
  end

  def new
  end

  def search
    @media = Medium.where(sort: search_sorts, teachable: search_teachables)
    @media = @media.select { |m| (m.tags & search_tags).present? }
    @media = @media.select { |m| (m.editors & search_editors).present? }
  end

  private

  def set_medium
    @medium = Medium.find_by_id(params[:id])
    return if @medium.present?
    redirect_to :root, alert: 'Ein Medium mit der angeforderten id existiert ' \
                              'nicht.'
  end

  def set_course
    @course = Course.find_by_id(params[:course_id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Modul mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def check_project
    return unless params[:project]
    return if @course.available_food.include?(params[:project])
    redirect_to :root, alert: 'Ein solches MaMpf-Teilprojekt existiert ' \
                              'für dieses Modul nicht.'
  end

  def sanitize_params
    sanitize_page!
    sanitize_per!
    params[:all] = params[:all] == 'true'
    params[:reverse] = params[:reverse] == 'true'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def paginated_results
    return Kaminari.paginate_array(search_results) if params[:all]
    Kaminari.paginate_array(search_results).page(params[:page])
            .per(params[:per])
  end

  def search_results
    search_results = Medium.search(@course.primary_lecture(current_user),
                                   params)
    return search_results unless params[:reverse]
    search_results.reverse
  end

  def sanitize_page!
    params[:page] = params[:page].to_i > 0 ? params[:page].to_i : 1
  end

  def sanitize_per!
    params[:per] = if params[:per].to_i.in?([3, 4, 8, 12, 24])
                     params[:per].to_i
                   else
                     8
                   end
  end

  def search_params
    params.require(:search).permit(:all_types, :all_teachables, :all_tags,
                                   :all_editors, types: [], teachable_ids: [],
                                   tag_ids: [], editor_ids: [])
  end

  def search_sorts
    return Medium.sort_enum unless search_params[:all_types] == '0'
    types = search_params[:types] || []
    types.map(&:to_i).map { |i| Medium.sort_enum[i] }
  end

  def search_teachables
    unless search_params[:all_teachables] == '0'
      return Course.all + Lecture.all + Lesson.all
    end
    lectures = Lecture.where(id: search_lecture_ids)
    courses = Course.where(id: search_course_ids)
    lessons = lectures.collect(&:lessons).flatten
    courses + lectures +lessons
  end

  def search_tags
    return Tag.all unless search_params[:all_tags] == '0'
    tag_ids = search_params[:tag_ids] || []
    Tag.where(id: tag_ids)
  end

  def search_editors
    return User.editors unless search_params[:all_editors] == '0'
    editor_ids = search_params[:editor_ids] || []
    editors = User.where(id: editor_ids)
  end

  def search_lecture_ids
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('lecture')}
                 .map { |t| t.remove('lecture-')}
  end

  def search_course_ids
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('course')}
                 .map { |t| t.remove('course-')}
  end
end
