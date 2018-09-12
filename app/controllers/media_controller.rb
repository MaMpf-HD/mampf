# MediaController
class MediaController < ApplicationController
  skip_before_action :authenticate_user!, only: [:play]
  before_action :set_medium, except: [:index, :catalog, :new, :create, :search]
  before_action :set_course, only: [:index]
  before_action :check_project, only: [:index]
  before_action :sanitize_params
  before_action :check_for_consent, except: [:play]
  authorize_resource

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
    if params[:teachable_type].in?(['Course', 'Lecture', 'Lesson']) &&
       params[:teachable_id].present?
      teachable = params[:teachable_type].constantize
                                         .find_by_id(params[:teachable_id])
    end
    @medium = Medium.new(teachable: teachable)
    @medium.editors << current_user
    tags = Tag.where(id: params[:tag_ids])
    @medium.tags << tags if tags.present?
  end

  def edit
  end

  def update
    @medium.update(medium_params)
    @errors = @medium.errors
    return unless @errors.empty?
    if params[:medium][:detach_video] == 'true'
      @medium.update(video: nil)
      @medium.update(screenshot: nil)
    end
    if params[:medium][:detach_manuscript] == 'true'
      @medium.update(manuscript: nil)
    end
    redirect_to edit_medium_path(@medium)
  end

  def create
    @medium = Medium.new(medium_params)
    @medium.save
    if @medium.valid?
      redirect_to edit_medium_path(@medium)
      return
    end
    @errors = @medium.errors
    render :update
  end

  def destroy
    @medium.destroy
    redirect_to administration_path
  end

  def inspect
  end

  def search
    @media = Medium.where(sort: search_sorts, teachable: search_teachables)
    tags = search_tags
    editors = search_editors
    @media = @media.select { |m| (m.tags & tags).present? }
    @media = @media.select { |m| (m.editors & editors).present? }
  end

  def play
    @toc = @medium.toc_to_vtt.remove(Rails.root.join('public').to_s)
    @ref = @medium.references_to_vtt.remove(Rails.root.join('public').to_s)
    @time = params[:time]
  end

  def add_item
    @time = params[:time].to_f
    @item = Item.new(medium: @medium,
                     start_time: TimeStamp.new(total_seconds: @time))
  end

  def add_reference
    @time = params[:time].to_f
    @end_time = [@time + 60, @medium.video_duration].min
    @referral = Referral.new(medium: @medium,
                             start_time: TimeStamp.new(total_seconds: @time),
                             end_time: TimeStamp.new(total_seconds: @end_time))
    @item_selection = @medium.items_for_thyme
  end

  def add_screenshot
    tempfile = Tempfile.new(['screenshot', '.png'])
    File.open(tempfile, 'wb') do |f|
      f.write params[:image].read
    end
    @medium.screenshot = File.open(tempfile)
    @medium.save
    respond_to do |format|
      format.js { render :add_screenshot }
    end
  end

  def remove_screenshot
    return if @medium.screenshot.nil?
    @medium.update(screenshot: nil)
  end

  def enrich
  end

  def export_toc
    file = @medium.toc_to_vtt
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'toc-' + @medium.title + '.vtt',
              type: 'content-type',
              x_sendfile: true
  end

  def export_references
    file = @medium.references_to_vtt
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'references-' + @medium.title + '.vtt',
              type: 'content-type',
              x_sendfile: true
  end

  def export_screenshot
    return if @medium.screenshot.nil?
    path = Rails.root.join('public', 'tmp')
    file = Tempfile.new(['screenshot', '.png'], path)
    @medium.screenshot.stream(file.path)
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'screenshot-' + @medium.title + '.png',
              type: 'content-type',
              x_sendfile: true
  end

  private

  def set_medium
    @medium = Medium.find_by_id(params[:id])
    return if @medium.present?
    redirect_to :root, alert: 'Ein Medium mit der angeforderten id existiert ' \
                              'nicht.'
  end

  def medium_params
    params.require(:medium).permit(:sort,:description, :video, :manuscript,
                                   :external_reference_link, :teachable_type,
                                   :teachable_id, editor_ids: [], tag_ids: [],
                                   linked_medium_ids: [])
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
                                   :all_editors,
                                   types: [],
                                   teachable_ids: [],
                                   tag_ids: [],
                                   editor_ids: [])
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
    courses + lectures + lessons
  end

  def search_tags
    return Tag.all unless search_params[:all_tags] == '0'
    tag_ids = search_params[:tag_ids] || []
    Tag.where(id: tag_ids)
  end

  def search_editors
    return User.editors unless search_params[:all_editors] == '0'
    editor_ids = search_params[:editor_ids] || []
    User.where(id: editor_ids)
  end

  def search_lecture_ids
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('lecture') }
                 .map { |t| t.remove('lecture-') }
  end

  def search_course_ids
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('course') }
                 .map { |t| t.remove('course-') }
  end
end
