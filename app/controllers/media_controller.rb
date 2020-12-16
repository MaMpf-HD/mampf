# MediaController
class MediaController < ApplicationController
  skip_before_action :authenticate_user!, only: [:play, :display]
  before_action :set_medium, except: [:index, :catalog, :new, :create, :search,
                                      :fill_teachable_select,
                                      :fill_media_select]
  before_action :set_lecture, only: [:index]
  before_action :set_teachable, only: [:new]
  before_action :sanitize_params, only: [:index]
  before_action :check_for_consent, except: [:play, :display]
  after_action :store_access, only: [:play, :display]
  after_action :store_download, only: [:register_download]
  authorize_resource
  layout 'administration'

  def index
    @media = paginated_results
    render layout: 'application'
  end

  def catalog
  end

  def show
    # destroy the notifications related to the medium
    current_user.notifications.where(notifiable_type: 'Medium',
                                     notifiable_id: @medium.id).each(&:destroy)
    I18n.locale = @medium.locale_with_inheritance
    commontator_thread_show(@medium)
    render layout: 'application_no_sidebar'
  end

  def new
    @medium = Medium.new(teachable: @teachable,
                         level: 1,
                         locale: @teachable.locale_with_inheritance)
    I18n.locale = @teachable.locale_with_inheritance
    @medium.sort = params[:sort] ? params[:sort] : 'Kaviar'
  end

  def edit
    I18n.locale = @medium.locale_with_inheritance
    @manuscript = Manuscript.new(@medium)
  end

  def update
    I18n.locale = @medium.locale_with_inheritance
    old_manuscript_data = @medium.manuscript_data
    old_video_data = @medium.video_data
    old_geogebra_data = @medium.geogebra_data
    @medium.update(medium_params)
    @errors = @medium.errors
    return unless @errors.empty?
    # make sure the medium is touched
    # (it will not be touched automatically in some cases (e.g. if you only
    # update the associated tags), causing trouble for caching)
    @medium.touch
    # touch lectures that import this medium
    @medium.importing_lectures.update_all(updated_at: Time.now)
    @medium.sanitize_type!
    # detach components if this was chosen by the user
    detach_components
    # create screenshot for manuscript if necessary
    changed_manuscript = @medium.manuscript_data != old_manuscript_data
    if @medium.manuscript.present? && changed_manuscript
      @medium.manuscript_derivatives!
      @medium.save
    end
    changed_geogebra = @medium.geogebra_data != old_geogebra_data
    if @medium.geogebra.present? && changed_geogebra
      @medium.geogebra_derivatives!
      @medium.save
    end
    changed_video = @medium.video_data != old_video_data
    if @medium.video.present? && changed_video
      MetadataExtractor.perform_async(@medium.id)
      # @medium.video.refresh_metadata!(action: :store)
      # refreshed_video = @medium.video
      # @medium.update(video_data: refreshed_video.to_json)
    end
    if @medium.sort == 'Quiz' &&params[:medium][:create_quiz_graph] == '1'
      @medium.becomes(Quiz).update(level: 1,
                                   quiz_graph: QuizGraph.new(vertices: {},
                                               edges: {},
                                               root: 0,
                                               default_table: {},
                                               hide_solution: []))
    end
    # if changes to the manuscript have been made,
    # remove items that correspond to named destinations that no longer
    # exist in the manuscript, but keep those that are referenced
    # from other places
    if @medium.sort == 'Script' && changed_manuscript
      @medium.update(imported_manuscript: false)
      @quarantine_added = @medium.update_pdf_destinations!
      if @quarantine_added.any?
        render :destination_warning
        return
      end
    end
    comments_locked = params[:medium][:comments_locked].to_i == 1
    if @medium.commontator_thread.is_closed? != comments_locked
      if comments_locked
        @medium.commontator_thread.close(current_user)
      else
        @medium.commontator_thread.reopen
      end
    end
    @tags_without_section = []
    return unless @medium.teachable.class.to_s == 'Lesson'
    add_tags_in_lesson_and_sections
  end

  def create
    @medium = Medium.new(medium_params)
    @medium.locale = @medium.teachable&.locale
    @medium.editors = [current_user]
    if @medium.teachable.class.to_s == 'Lesson'
      @medium.tags = @medium.teachable.tags
    end
    @medium.save
    if @medium.valid?
      if @medium.sort == 'Remark'
        @medium.update(type: 'Remark',
                       text: I18n.t('admin.remark.initial_text'))
      end
      if @medium.sort == 'Question'
        solution = Solution.new(MampfExpression.trivial_instance)
        @medium.update(type: 'Question',
                       text: I18n.t('admin.question.initial_text'),
                       level: 1,
                       independent: false,
                       solution: solution,
                       question_sort: 'mc')
        Answer.create(question: @medium.becomes(Question),
                      text: '0',
                      value: true)
      end
      if @medium.sort == 'Quiz'
        @medium.update(type: 'Quiz')
        @medium.update(quiz_graph:QuizGraph.new(vertices: {},
                                                edges: {},
                                                root: 0,
                                                default_table: {},
                                                hide_solution: []),
                       level: 1)
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
    lock_comments = params[:medium][:lock_comments]
    @medium.commontator_thread.close(current_user) if lock_comments.to_i == 1
    if @medium.sort == 'Quiz' && params[:medium][:publish_vertices] == '1'
      @medium.becomes(Quiz).publish_vertices!(current_user, release_state)
    end
    # create notification about creation of medium to all subscribers
    # and send an email
    unless @medium.sort.in?(['Question', 'Remark', 'RandomQuiz'])
      @medium.teachable&.media_scope&.touch
      create_notifications
      send_notification_email
    end
    redirect_to edit_medium_path(@medium)
  end

  def destroy
    @medium.destroy
    # destroy all notifications related to this medium
    destroy_notifications
    @medium.teachable.touch
    if @medium.teachable_type == 'Lecture'
      redirect_to edit_lecture_path(@medium.teachable)
      return
    end
    if @medium.teachable_type == 'Lesson'
      redirect_to edit_lesson_path(@medium.teachable)
      return
    end
    redirect_to edit_course_path(@medium.teachable)
  end

  def inspect
  end

  # return all media that match the search parameters
  def search
    search = Medium.search_by(search_params, params[:page])
    search.execute
    results = search.results
    @total = search.total
    @media = Kaminari.paginate_array(results, total_count: @total)
                     .page(params[:page]).per(search_params[:per])
    @purpose = search_params[:purpose]
    if @purpose.in?(['quiz', 'import'])
      render template: "media/catalog/import_preview"
      return
    end
  end

  # play the video using thyme player
  def play
    if @medium.video.nil?
      redirect_to :root, alert: I18n.t('controllers.no_video')
      return
    end
    I18n.locale = @medium.locale_with_inheritance
    @vtt_container = @medium.create_vtt_container!
    @time = params[:time]
    render layout: 'thyme'
  end

  # show the pdf, optionally at specified page or named destination
  def display
    if @medium.manuscript.nil?
      redirect_to :root, alert: I18n.t('controllers.no_manuscript')
      return
    end
    if params[:destination].present?
      redirect_to @medium.manuscript_url_with_host + '#' + params[:destination].to_s
      return
    elsif params[:page].present?
      redirect_to @medium.manuscript_url_with_host + '#page=' + params[:page].to_s
      return
    end
    redirect_to @medium.manuscript_url_with_host
  end

  # run the geogebra applet using Geogebra's Javascript API
  def geogebra
    if @medium.geogebra.nil?
      redirect_to :root, alert: I18n.t('controllers.no_geogebra')
      return
    end
    I18n.locale = @medium.locale_with_inheritance
    render layout: 'geogebra'
  end

  # add a toc item for the video
  def add_item
    I18n.locale = @medium.locale_with_inheritance
    @time = params[:time].to_f
    @item = Item.new(medium: @medium,
                     start_time: TimeStamp.new(total_seconds: @time))
    if @medium.sort == 'Kaviar' &&
        @medium.teachable_type.in?(['Lesson', 'Lecture'])
      @item.section = @medium.teachable&.sections&.first
    end
  end

  # add a reference for the video
  def add_reference
    I18n.locale = @medium.locale_with_inheritance
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
    if @medium.valid?
      @medium.screenshot_derivatives!
      @medium.save
    end
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
    I18n.locale = @medium.locale_with_inheritance
    render layout: 'enrich'
  end

  # if the medium is associated to a lesson of a lecture which is in script mode
  # and the lesson has associated script-items, it is possible to import these
  # items into the toc of the medium
  def import_script_items
    @medium.import_script_items!
  end

  # export the video's toc data to a .vtt file
  def export_toc
    @vtt_container = @medium.create_vtt_container!
    file = Tempfile.new
    @vtt_container.table_of_contents.stream(file.path)

    send_file file,
              filename: 'toc-' + @medium.title + '.vtt',
              type: 'text/vtt',
              disposition: 'attachment'
  end

  # export the video's references to a .vtt file
  def export_references
    @vtt_container = @medium.create_vtt_container!
    file = Tempfile.new
    @vtt_container.references.stream(file.path)

    send_file file,
              filename: 'references-' + @medium.title + '.vtt',
              type: 'text/vtt',
              disposition: 'attachment'
  end

  # export the video's screenshot to a .vtt file
  def export_screenshot
    return if @medium.screenshot.nil?
    file = Tempfile.new
    @medium.screenshot.stream(file.path)

    send_file file,
              filename: 'screenshot-' + @medium.title + '.png',
              type: 'image/png',
              disposition: 'attachment'
  end

  # imports all of manuscript destinations, bookmarks as chpters, sections etc.
  def import_manuscript
    manuscript = Manuscript.new(@medium)
    filter_boxes = JSON.parse(params[:filter_boxes])
    manuscript.export_to_db!(filter_boxes)
    @medium.update(imported_manuscript: true)
    @quarantine_added = @medium.update_pdf_destinations!
    if @quarantine_added.any?
      render :destination_warning
      return
    end
    redirect_to edit_medium_path(@medium)
  end

  def fill_teachable_select
    result = (Course.editable_selection(current_user) +
                Lecture.editable_selection(current_user) +
                Lesson.editable_selection(current_user))
               .map { |t| { value: t[1], text: t[0] } }
    render json: result
  end

  def fill_media_select
    result = Medium.select_by_name.map { |t| { value: t[1], text: t[0] } }
    render json: result
  end

  def update_tags
    if current_user.admin || @medium.edited_with_inheritance_by?(current_user)
      @medium.tags = Tag.where(id: params[:tag_ids])
      @medium.update(updated_at: Time.now)
    end
  end

  def postprocess_tags
  end

  def register_download
    head :ok
  end

  def get_statistics
    medium_consumption = Consumption.where(medium_id: @medium.id)
    if @medium.video.present?
      @video_downloads = medium_consumption.where(sort: 'video',
                                                  mode: 'download').count
      @video_thyme = medium_consumption.where(sort: 'video',
                                              mode: 'thyme').count
    end
    if @medium.manuscript.present?
      @manuscript_access = medium_consumption.where(sort: 'manuscript').count
    end
    if @medium.sort == 'Quiz'
      @quiz_access = Probe.finished_quizzes(@medium)
      @global_success = Probe.global_success_in_quiz(@medium.becomes(Quiz))
      @global_success_details = Probe.global_success_details(@medium.becomes(Quiz))
      @question_count = @medium.becomes(Quiz).questions_count
      @local_success = Probe.local_success_in_quiz(@medium.becomes(Quiz))
    end
  end

  def show_comments
    commontator_thread_show(@medium)
    render layout: 'application_no_sidebar'
  end

  private

  def medium_params
    params.require(:medium).permit(:sort, :description, :video, :manuscript,
                                   :external_reference_link,
                                   :geogebra, :geogebra_app_name,
                                   :teachable_type, :teachable_id,
                                   :released, :text, :locale,
                                   :content, :boost,
                                   editor_ids: [],
                                   tag_ids: [],
                                   linked_medium_ids: [])
  end

  def set_medium
    @medium = Medium.find_by_id(params[:id])&.becomes(Medium)
    return if @medium.present? && @medium.sort != 'RandomQuiz'
    redirect_to :root, alert: I18n.t('controllers.no_medium')
  end

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    # store current lecture in cookie
    if @lecture
      cookies[:current_lecture_id] = strict_cookie(@lecture.id)
      return
    end
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def set_teachable
    if params[:teachable_type].in?(['Course', 'Lecture', 'Lesson']) &&
       params[:teachable_id].present?
      @teachable = params[:teachable_type].constantize
                                          .find_by_id(params[:teachable_id])
    end
  end

  def detach_components
    if params[:medium][:detach_video] == 'true'
      @medium.update(video: nil)
      @medium.update(screenshot: nil)
    end
    if params[:medium][:detach_geogebra] == 'true'
      @medium.update(geogebra: nil)
    end
    return unless params[:medium][:detach_manuscript] == 'true'
    @medium.update(manuscript: nil)
  end

  def sanitize_params
    reveal_contradictions
    sanitize_page!
    sanitize_per!
    params[:all] = (params[:all] == 'true') || (cookies[:all] == 'true')
    cookies[:all] = strict_cookie(params[:all])
    cookies[:per] = strict_cookie(false) if cookies[:all]
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
    search_results = Medium.search_all(params)
    # search_results are ordered in a certain way
    # the next lines ensure that filtering for visible media does not
    # mess up the ordering
    search_arel = Medium.where(id: search_results.pluck(:id))
    visible_search_results = current_user.filter_visible_media(search_arel)
    search_results &= visible_search_results
    total = search_results.size
    @lecture = Lecture.find_by_id(params[:id])
    # filter out stuff from course level for generic users
    if params[:visibility] == 'lecture'
      search_results.reject! { |m| m.teachable_type == 'Course' }
      # yields only lecture media and course media
    elsif params[:visibility] == 'all'
      # yields all lecture media and course media
    else
      # this is the default setting: 'thematic' selection of media
      # yields all lecture media and course media whose tags have
      # already been dealt with in the lecture
      unless current_user.admin || @lecture.edited_by?(current_user)
        lecture_tags = @lecture.tags_including_media_tags
        search_results.reject! do |m|
          m.teachable_type == 'Course' && (m.tags & lecture_tags).blank?
        end
      end
    end
    sort = params[:project] == 'keks' ? 'Quiz' : params[:project]&.capitalize
    search_results +=  @lecture.imported_media
                               .where(sort: sort)
                               .locally_visible
    search_results.uniq!
    @hidden = search_results.empty? && total.positive?
    return search_results unless params[:reverse]
    search_results.reverse
  end

  def reveal_contradictions
    return unless params[:lecture_id].present?
    return if params[:lecture_id].to_i.in?(@course.lecture_ids)
    redirect_to :root, alert: I18n.t('controllers.contradiction')
  end

  def sanitize_page!
    params[:page] = params[:page].to_i.positive? ? params[:page].to_i : 1
  end

  def sanitize_per!
    if params[:per] || cookies[:per].to_i.positive?
      cookies[:all] = strict_cookie('false')
    end
    params[:per] = if params[:per].to_i.in?([3, 4, 8, 12, 24, 48])
                     params[:per].to_i
                   elsif cookies[:per].to_i.positive?
                     cookies[:per].to_i
                   else
                     8
                   end
    cookies[:per] = strict_cookie(params[:per])
  end

  def search_params
    types = params[:search][:types]
    types = [types] if types && !types.kind_of?(Array)
    types -= [''] if types
    types = nil if types == []
    params[:search][:types] = types
    params.require(:search).permit(:all_types, :all_teachables, :all_tags,
                                   :all_editors, :tag_operator, :quiz, :access,
                                   :teachable_inheritance, :fulltext, :per,
                                   :clicker, :purpose, :answers_count,
                                   types: [],
                                   teachable_ids: [],
                                   tag_ids: [],
                                   editor_ids: [])
  end

  # create notifications to all users who are subscribed
  # to the medium's teachable's media_scope
  def create_notifications
    notifications = []
    @medium.teachable.media_scope.users.update_all(updated_at: Time.now)
    @medium.teachable.media_scope.users.each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @medium.id,
                                        notifiable_type: 'Medium',
                                        action: 'create')
    end
    Notification.import notifications
  end

  def send_notification_email
    recipients = @medium.teachable.media_scope.users
                        .where(email_for_medium: true)
    I18n.available_locales.each do |l|
      local_recipients = recipients.where(locale: l)
      if local_recipients.any?
        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                medium: @medium)
                          .medium_email.deliver_later
      end
    end
  end

  # destroy all notifications related to this medium
  def destroy_notifications
    Notification.where(notifiable_id: @medium.id, notifiable_type: 'Medium')
                .delete_all
  end

  def add_tags_in_lesson_and_sections
    @tags_outside_lesson = @medium.tags_outside_lesson
    if @tags_outside_lesson
      @medium.teachable.tags << @tags_outside_lesson
      @tags_without_section = @tags_outside_lesson & @medium.teachable.tags_without_section
      if @medium.teachable.sections.count == 1
        section = @medium.teachable.sections.first
        section.tags << @tags_without_section
      end
    end
  end

  def store_access
    mode = action_name == 'play' ? 'thyme' : 'pdf_view'
    sort = action_name == 'play' ? 'video' : 'manuscript'
    ConsumptionSaver.perform_async(@medium.id, mode, sort)
  end

  def store_download
    ConsumptionSaver.perform_async(@medium.id, 'download', params[:sort])
  end
end
