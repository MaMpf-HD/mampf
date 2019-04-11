# MediaController
class MediaController < ApplicationController
  skip_before_action :authenticate_user!, only: [:play, :display]
  before_action :set_medium, except: [:index, :catalog, :new, :create, :search]
  before_action :set_course, only: [:index]
  before_action :check_project, only: [:index]
  before_action :set_teachable, only: [:new]
  before_action :sanitize_params
  before_action :check_for_consent, except: [:play, :display]
  authorize_resource
  layout 'administration'

  def index
    cookies[:current_course] = params[:course_id]
    if params[:lecture_id].present? &&
      params[:current_lecture].in?(current_user.lecture_ids)
      cookies[:current_lecture] = params[:lecture_id]
    end
    @media = paginated_results
    render layout: 'application'
  end

  def catalog
  end

  def show
    # destroy the notifications related to the medium
    current_user.notifications.where(notifiable_type: 'Medium',
                                     notifiable_id: @medium.id).each(&:destroy)
    render layout: 'application_no_sidebar'
  end

  def new
    @medium = Medium.new(teachable: @teachable, level: 1)
    @medium.editors << current_user
    tags = Tag.where(id: params[:tag_ids])
    @medium.tags << tags if tags.exists?
    @medium.sort = params[:sort] ? params[:sort] : 'Kaviar'
  end

  def edit
    @manuscript = Manuscript.new(@medium)
  end

  def update
    @medium.update(medium_params)
    @errors = @medium.errors
    return unless @errors.empty?
    # make sure the medium is touched
    # (it will not be touched automatically in some cases (e.g. if you only
    # update the associated tags), causing trouble for caching)
    @medium.touch
    # detach the video or manuscript if this was chosen by the user
    detach_video_or_manuscript
    if @medium.sort == 'KeksQuiz' &&params[:medium][:create_quiz_graph] == '1'
      @medium.becomes(Quiz).update(level: 1,
                                   quiz_graph: QuizGraph.new(vertices: {},
                                               edges: {},
                                               root: 0,
                                               default_table: {},
                                               hide_solution: []))
      @medium.becomes(Quiz).save_png!
    end
    # if changes to the manuscript have been made,
    # remove items that correspond to named destinations that no longer
    # exist in the manuscript, but keep those that are referenced
    # from other places
    if @medium.sort == 'Script' && @medium.saved_change_to_manuscript_data?
      @medium.update(imported_manuscript: false)
      @quarantine_added = @medium.update_pdf_destinations!
      if @quarantine_added.any?
        render :destination_warning
        return
      end
    end
    redirect_to edit_medium_path(@medium)
  end

  def create
    @medium = Medium.new(medium_params)
    @medium.save
    if @medium.valid?
      if @medium.sort == 'KeksRemark'
        @medium.update(type: 'Remark', text: 'Dummytext')
      end
      if @medium.sort == 'KeksQuestion'
        @medium.update(type: 'Question', text: 'Dummytext', level: 1,
                       independent: false)
        Answer.create(question: @medium.becomes(Question),
                      text: 'Dummyantwort',
                      value: true)
      end
      if @medium.sort == 'KeksQuiz'
        @medium.update(type: 'Quiz')
        if params[:medium][:create_quiz_graph] == '1'
          @medium.update(quiz_graph:QuizGraph.new(vertices: {},
                                                  edges: {},
                                                  root: 0,
                                                  default_table: {},
                                                  hide_solution: []),
                         level: 1)
          @medium.becomes(Quiz).save_png!
        end
      end
      redirect_to edit_medium_path(@medium)
      return
    end
    @errors = @medium.errors
    render :update
  end

  def publish
    release_state = params[:medium][:released]
    @medium.update(released: release_state)
    # create notification about creation of medium to all subscribers
    create_notifications unless @medium.sort.in?(['KeksQuestion', 'KeksRemark',
                                                  'RandomQuiz'])
    redirect_to edit_medium_path(@medium)
  end

  def destroy
    @medium.destroy
    # destroy all notifications related to this medium
    destroy_notifications
    if @medium.teachable_type.in?(['Lecture', 'Lesson'])
      redirect_to edit_lecture_path(@medium.teachable.media_scope)
      return
    end
    redirect_to edit_course_path(@medium.teachable)
  end

  def inspect
  end

  # return all media that match the search parameters
  def search
    @media = Medium.search_by_attributes(search_params)
  end

  # play the video using thyme player
  def play
    if @medium.video.nil?
      redirect_to :root, alert: 'Zu diesem Medium existiert kein Video.'
      return
    end
    @toc = @medium.toc_to_vtt.remove(Rails.root.join('public').to_s)
    @ref = @medium.references_to_vtt.remove(Rails.root.join('public').to_s)
    @time = params[:time]
    render layout: 'thyme'
  end

  # show the pdf, optionally at specified page or named destination
  def display
    if @medium.manuscript.nil?
      redirect_to :root, alert: 'Zu diesem Medium existiert kein Manuskript.'
      return
    end
    if params[:destination].present?
      redirect_to @medium.manuscript_url + '#' + params[:destination].to_s
      return
    elsif params[:page].present?
      redirect_to @medium.manuscript_url + '#page=' + params[:page].to_s
      return
    end
    redirect_to @medium.manuscript_url
  end

  # add a toc item for the video
  def add_item
    @time = params[:time].to_f
    @item = Item.new(medium: @medium,
                     start_time: TimeStamp.new(total_seconds: @time))
  end

  # add a reference for the video
  def add_reference
    @time = params[:time].to_f
    @end_time = [@time + 60, @medium.video_duration].min
    @referral = Referral.new(medium: @medium,
                             start_time: TimeStamp.new(total_seconds: @time),
                             end_time: TimeStamp.new(total_seconds: @end_time))
    @item_selection = @medium.teachable.media_scope.media_items_with_inheritance
    @item = Item.new(sort: 'link')
  end

  # add a screenshot for the video
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

  # remove the video's screenshot
  def remove_screenshot
    return if @medium.screenshot.nil?
    @medium.update(screenshot: nil)
  end

  # start the thyme editor
  def enrich
  end

  # export the video's toc data to a .vtt file
  def export_toc
    file = @medium.toc_to_vtt
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'toc-' + @medium.title + '.vtt',
              type: 'content-type',
              x_sendfile: true
  end

  # export the video's references to a .vtt file
  def export_references
    file = @medium.references_to_vtt
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'references-' + @medium.title + '.vtt',
              type: 'content-type',
              x_sendfile: true
  end

  # export the video's screenshot to a .vtt file
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

  # imports all of manuscript destinations, bookmarks as chpters, sections etc.
  def import_manuscript
    manuscript = Manuscript.new(@medium)
    filter_boxes = JSON.parse(params[:filter_boxes])
    manuscript.export_to_db!(filter_boxes)
    @medium.update(imported_manuscript: true)
    redirect_to edit_medium_path(@medium)
  end

  private

  def medium_params
    params.require(:medium).permit(:sort, :description, :video, :manuscript,
                                   :external_reference_link, :teachable_type,
                                   :teachable_id, :released, :text,
                                   editor_ids: [],
                                   tag_ids: [],
                                   linked_medium_ids: [])
  end

  def set_medium
    @medium = Medium.find_by_id(params[:id])&.becomes(Medium)
    return if @medium.present? && @medium.sort != 'RandomQuiz'
    redirect_to :root, alert: 'Ein Medium mit der angeforderten id existiert ' \
                              'nicht.'
  end

  def set_course
    @course = Course.find_by_id(params[:course_id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Modul mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def set_teachable
    if params[:teachable_type].in?(['Course', 'Lecture', 'Lesson']) &&
       params[:teachable_id].present?
      @teachable = params[:teachable_type].constantize
                                          .find_by_id(params[:teachable_id])
    end
  end

  def detach_video_or_manuscript
    if params[:medium][:detach_video] == 'true'
      @medium.update(video: nil)
      @medium.update(screenshot: nil)
    end
    return unless params[:medium][:detach_manuscript] == 'true'
    @medium.update(manuscript: nil)
  end

  def check_project
    return unless params[:project]
    return if @course.available_food.include?(params[:project])
    redirect_to :root, alert: 'Ein solches MaMpf-Teilprojekt existiert ' \
                              'für dieses Modul nicht.'
  end

  def sanitize_params
    reveal_contradictions
    sanitize_page!
    sanitize_per!
    params[:all] = params[:all] == 'true'
    params[:reverse] = params[:reverse] == 'true'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  # paginate results obtained by the search_results method
  def paginated_results
    if params[:all]
      total_count = search_results.count
      # without the total count parameter, kaminary will consider only only the
      # first 25 entries
      return Kaminari.paginate_array(search_results,
                                     total_count: total_count + 1)
    end
    Kaminari.paginate_array(search_results).page(params[:page])
            .per(params[:per])
  end

  # search is done in search class method for Medium
  def search_results
    search_results = Medium.search(@course.primary_lecture(current_user),
                                   params)
                           .select { |m| m.visible_for_user?(current_user) }
    return search_results unless params[:reverse]
    search_results.reverse
  end

  def reveal_contradictions
    return unless params[:lecture_id].present?
    return if params[:lecture_id].in?(@course.lecture_ids)
    redirect_to :root, alert: 'Wiedersprüchliche Suchanfrage.'
  end

  def sanitize_page!
    params[:page] = params[:page].to_i.positive? ? params[:page].to_i : 1
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

  # create notifications to all users who are subscribed
  # to the medium's teachable's media_scope
  def create_notifications
    notifications = []
    @medium.teachable.media_scope.users.where(no_notifications: false)
           .each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @medium.id,
                                        notifiable_type: 'Medium',
                                        action: 'create')
    end
    Notification.import notifications
  end

  # destroy all notifications related to this medium
  def destroy_notifications
    Notification.where(notifiable_id: @medium.id, notifiable_type: 'Medium')
                .delete_all
  end
end
