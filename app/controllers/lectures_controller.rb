# LecturesController
class LecturesController < ApplicationController
  include ActionController::RequestForgeryProtection

  before_action :set_lecture, except: [:new, :create, :search]
  before_action :set_lecture_cookie, only: [:show, :outline, :organizational,
                                            :show_announcements]
  authorize_resource except: [:new, :create, :search, :outline]
  before_action :check_for_consent
  before_action :check_for_unlock, only: [:outline]
  before_action :check_if_enough_questions, only: [:show_random_quizzes]
  before_action :require_turbo_frame, only: [:new]
  layout "staff"

  def current_ability
    @current_ability ||= LectureAbility.new(current_user)
  end

  def show
    if lecture_home_landing_page?
      redirect_to lecture_home_path(@lecture)
    else
      redirect_to lecture_outline_path(@lecture)
    end
  end

  def outline
    authorize! :show, @lecture
    render_outline
  end

  def new
    @lecture = Lecture.new(sort: "lecture")
    authorize! :new, @lecture
    @from = params[:from]

    if @from == "course"
      # if new action was triggered from inside a course view, add the course
      # info to the lecture
      @lecture.course = Course.find_by(id: params[:course])
      @lecture.annotations_status = 0
    end

    render turbo_stream: turbo_stream.update(turbo_frame_request_id,
                                             partial: "lectures/new/new",
                                             locals: { lecture: @lecture, from: @from })
  end

  def edit
    eager_load_stuff
    if params[:campaign_id]
      @campaign = @lecture.registration_campaigns.find_by(id: params[:campaign_id])
    elsif params[:new_campaign]
      @new_campaign = @lecture.registration_campaigns.build
    end
    render template: "lectures/edit/edit"
  end

  def create
    @lecture = Lecture.new(lecture_params)
    @lecture.teacher = current_user unless current_user.admin?
    authorize! :create, @lecture

    if @lecture.save
      @lecture.update(sort: "special") if @lecture.course.term_independent
      # set organizational_concept to default
      set_organizational_defaults
      # set language to default language
      set_language

      flash.now[:notice] = I18n.t("controllers.created_lecture_success",
                                  lecture: @lecture.title_with_teacher)

      streams = []

      if params.dig(:lecture, :from) == "course"
        streams << turbo_stream.update("course_lectures",
                                       partial: "courses/lectures_list",
                                       locals: { course: @lecture.course })
        streams << turbo_stream.update(Lecture.new,
                                       partial: "spinner/loading")
      else
        streams << turbo_stream.update("lectures",
                                       partial: "administration/index/lectures_list")
        streams << turbo_stream.update(Lecture.new, "")
      end

      streams << turbo_stream.prepend("flash-messages",
                                      partial: "flash/message")

      render turbo_stream: streams
    else
      @from = params.dig(:lecture, :from)

      render turbo_stream: turbo_stream.update(turbo_frame_request_id,
                                               partial: "lectures/new/new",
                                               locals: { lecture: @lecture, from: @from }),
             status: :unprocessable_content
    end
  end

  def update
    return unless @lecture.valid_annotations_status?

    attach_scanned_home_attachment
    new_editors = editors_to_notify
    update_lecture_and_forum
    notify_new_editors(new_editors) if @errors.empty?
    handle_update_response
  rescue MalwareScanGate::InfectedUploadError
    refuse_home_attachment(t("submission.upload_failure_malware"))
  rescue MalwareScanGate::ScannerUnavailableError
    refuse_home_attachment(t("submission.upload_failure_scanner_unavailable"))
  end

  def publish
    @lecture.update(released: "all")
    if params[:medium][:publish_media] == "1"
      @lecture.media_with_inheritance
              .update(released: params[:medium][:released])
    end
    # create notifications about creation od this lecture and send email
    create_notifications
    send_notification_email
    redirect_to edit_lecture_path(@lecture)
  end

  def destroy
    unless @lecture.destroy
      redirect_to edit_lecture_path(@lecture, tab: "groups"),
                  alert: lecture_destruction_error,
                  status: :see_other
      return
    end

    # destroy all notifications related to this lecture
    destroy_notifications
    redirect_to current_user.admin? ? administration_path : start_path,
                status: :see_other
  end

  # add forum for this lecture
  def add_forum
    unless @lecture.forum?
      forum = Thredded::Messageboard.new(name: @lecture.forum_title)
      forum.save
      @lecture.update(forum_id: forum.id) if forum.valid?
    end
    redirect_to "#{edit_lecture_path(@lecture)}?tab=communication"
  end

  # lock forum for this lecture
  def lock_forum
    @lecture.forum.update(locked: true) if @lecture.forum?
    @lecture.touch
    redirect_to "#{edit_lecture_path(@lecture)}?tab=communication"
  end

  # unlock forum for this lecture
  def unlock_forum
    @lecture.forum.update(locked: false) if @lecture.forum?
    @lecture.touch
    redirect_to "#{edit_lecture_path(@lecture)}?tab=communication"
  end

  # destroy forum for this lecture
  def destroy_forum
    @lecture.forum.destroy if @lecture.forum?
    @lecture.update(forum_id: nil)
    redirect_to "#{edit_lecture_path(@lecture)}?tab=communication"
  end

  # show all announcements for this lecture
  def show_announcements
    @announcements = @lecture.announcements.order(:created_at).reverse
    @active_notification_count = current_user.active_notifications(@lecture)
                                             .size
    render template: "lectures/announcements/show_announcements",
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def organizational
    render template: "lectures/organizational/_organizational",
           locals: { lecture: @lecture },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def import_media
    media = Medium.where(id: params[:media_ids])
                  .where.not(id: @lecture.imported_media.pluck(:id))
                  .where.not(teachable: @lecture)
    media.each { |m| Import.create(teachable: @lecture, medium: m) }
    @lecture.reload
    @lecture.touch

    render turbo_stream: [
      turbo_stream.update("importedMediaTable",
                          partial: "lectures/import/imported_media",
                          locals: { media: @lecture.imported_media,
                                    lecture: @lecture }),
      turbo_stream.replace("importMedia",
                           helpers.import_media_badge(@lecture)),
      turbo_stream.update("media-search-results", "")
    ]
  end

  def remove_imported_medium
    @medium = Medium.find_by(id: params[:medium])
    import = Import.find_by(teachable: @lecture, medium: @medium)
    import&.destroy
    @lecture.reload
    @lecture.touch

    render turbo_stream: [
      turbo_stream.update("importedMediaTable",
                          partial: "lectures/import/imported_media",
                          locals: { media: @lecture.imported_media,
                                    lecture: @lecture }),
      turbo_stream.replace("importMedia",
                           helpers.import_media_badge(@lecture))
    ]
  end

  def show_subscribers
    user_data = @lecture.users.pluck(:name, :email)
    render json: user_data
  end

  def close_comments
    @lecture.close_comments!(current_user)
    # disable annotation button
    @lecture.update(annotations_status: 0)
    @lecture.media.update(annotations_status: -1)
    @lecture.lessons.each do |lesson|
      lesson.media.update(annotations_status: -1)
    end
    @lecture.touch
    redirect_to "#{edit_lecture_path(@lecture)}?tab=communication"
  end

  def open_comments
    @lecture.open_comments!(current_user)
    @lecture.touch
    redirect_to "#{edit_lecture_path(@lecture)}?tab=communication"
  end

  def search
    authorize! :search, Lecture.new

    @pagy, @lectures = Search::Searchers::ControllerSearcher.search(
      controller: self,
      model_class: Lecture,
      configurator_class: Search::Configurators::LectureSearchConfigurator,
      options: { infinite_scroll: params[:infinite_scroll], default_per_page: 6 }
    )
    if @lectures.respond_to?(:includes)
      # avoid N+1 queries for the registration badge on the result cards
      @lectures = @lectures.includes(:registration_campaigns)
    end
    # ID sets for the state indicators on the result cards (computed once
    # per request and scoped to the current page, so the cards do not
    # trigger per-lecture queries and the cost is bounded by the page size)
    page_lecture_ids = @lectures.map(&:id)
    self_enrollment = Rosters::SelfEnrollmentStatusQuery.new(current_user, page_lecture_ids)
    @search_result_ids = LectureSearchResultComponent::PageIds.new(
      bookmarked_lecture_ids:
        current_user.lecture_bookmarks
                    .where(lecture_id: page_lecture_ids)
                    .pluck(:lecture_id).to_set,
      registration_status_by_lecture_id:
        Registration::StatusQuery.new(current_user, page_lecture_ids).statuses,
      rosterized_lecture_ids: self_enrollment.rosterized_lecture_ids,
      self_enrollable_lecture_ids: self_enrollment.enrollable_lecture_ids
    )

    # The dashboard search is scoped to one semester by the picker above it, so
    # the term on each result card is redundant there and switched off via a
    # hidden field. Other callers (e.g. /search/index) keep it.
    @show_term = params.dig(:search, :show_term) != "0"
    @search_term = Term.from_dashboard_param(params.dig(:search, :term))

    respond_to do |format|
      format.js { render template: "lectures/search/old/search" }
      format.turbo_stream do
        if @pagy.page == 1
          # initial rendering of first search results
          render turbo_stream: turbo_stream.replace("lecture-search-results-wrapper",
                                                    partial: "lectures/search/list")
        else
          # For infinite-scroll pagination, append results for subsequent pages
          render turbo_stream: [
            turbo_stream.replace("pagy-nav-next",
                                 partial: "lectures/search/nav",
                                 locals: { pagy: @pagy }),
            turbo_stream.append("lecture-search-results", search_result_cards)
          ]
        end
      end
      format.html do
        redirect_to :root, alert: I18n.t("controllers.search_only_js")
      end
    end
  end

  def show_random_quizzes
    @course = @lecture.course
    render template: "lectures/quizzes/show_random_quizzes",
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def display_course
    @course = @lecture.course
    render template: "lectures/course/display_course",
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def import_toc
    imported_lecture = Lecture
                       .find_by(id: import_toc_params[:imported_lecture_id])
    import_sections = import_toc_params[:import_sections] == "1"
    import_tags = import_toc_params[:import_tags] == "1"
    @lecture.import_toc!(imported_lecture, import_sections, import_tags)
    redirect_to edit_lecture_path(@lecture)
  end

  private

    def search_result_cards
      LectureSearchResultComponent.with_collection(
        @lectures, ids: @search_result_ids, user: current_user,
                   term: @search_term, show_term: @show_term
      )
    end

    def set_lecture
      @lecture = Lecture.find_by(id: params[:id])
      return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_lecture_cookie
      cookies[:current_lecture_id] = @lecture.id
    end

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end

    def check_for_unlock
      # Students of an open or unlocked lecture pass, and so does its staff.
      return if @lecture.content_accessible_by?(current_user)

      # Users who have not unlocked the lecture are sent to its home page
      # (its organizational front door), which offers registration (if the
      # lecture uses it) as well as the passphrase form to unlock it.
      redirect_to lecture_home_path(@lecture)
    end

    def render_outline
      # deactivate http caching for the moment
      if stale?(etag: @lecture,
                last_modified: [current_user.updated_at,
                                @lecture.updated_at,
                                Time.zone.parse(ENV.fetch("RAILS_CACHE_ID", nil)),
                                Thredded::UserDetail.find_by(user_id: current_user.id)
                                                    &.last_seen_at || @lecture.updated_at,
                                @lecture.forum&.updated_at || @lecture.updated_at].max)
        @lecture = Lecture.includes(:teacher, :term, :editors, :users,
                                    :announcements, :imported_media,
                                    course: [:editors],
                                    media: [:teachable, :tags],
                                    lessons: [media: [:tags]],
                                    chapters: [:lecture,
                                               { sections: [lessons: [:tags],
                                                            chapter: [:lecture],
                                                            tags: [:notions,
                                                                   :lessons]] }])
                          .find_by(id: params[:id])
        @notifications = current_user.active_notifications(@lecture)
        @new_topics_count = @lecture.unread_forum_topics_count(current_user) || 0

        render template: "lectures/show/show",
               layout: turbo_frame_request? ? "turbo_frame" : "application"
      end
    end

    def lecture_home_landing_page?
      @lecture.term.present? &&
        Flipper.enabled?(:lecture_home_landing, @lecture.term)
    end

    def lecture_params
      permitted_lecture_params.except(:home_attachment)
    end

    # Permits :home_attachment on update so a file-only request passes expect;
    # lecture_params leaves it out, attach_scanned_home_attachment attaches it.
    # The new-lecture form has no such field.
    def permitted_lecture_params
      allowed_params = [:term_id, :start_chapter, :absolute_numbering,
                        :start_section, :organizational, :locale,
                        :organizational_concept, :vignettes,
                        :organizational_on_top, :disable_teacher_display,
                        :content_mode, :passphrase, :sort, :comments_disabled,
                        :submission_max_team_size, :submission_grace_period,
                        :submission_deletion_date, :uses_exam_eligibility,
                        :annotations_status,
                        :home_intro, :remove_home_attachment]
      if action_name == "update"
        allowed_params.push(:home_attachment)
        allowed_params.push({ editor_ids: [] }) if current_user.can_update_personell?(@lecture)
      end
      allowed_params.push(:course_id, { editor_ids: [] }) if action_name == "create"
      allowed_params.push(:teacher_id) if current_user.admin?
      params.expect(lecture: allowed_params)
    end

    def import_toc_params
      params.permit(:imported_lecture_id, :import_sections, :import_tags)
    end

    # create notifications to all users about creation of new lecture
    def create_notifications
      notifications = []
      User.find_each do |u|
        notifications << Notification.new(recipient: u,
                                          notifiable_id: @lecture.id,
                                          notifiable_type: "Lecture",
                                          action: "create")
      end
      Notification.import notifications
    end

    def send_notification_email
      recipients = User.where(email_for_teachable: true)
      I18n.available_locales.each do |l|
        local_recipients = recipients.where(locale: l)
        next unless local_recipients.any?

        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                lecture: @lecture)
                          .new_lecture_email.deliver_later
      end
    end

    def lecture_destruction_error
      required_elsewhere = @lecture.registration_campaigns.any?(&:required_by_other_campaign?)
      return t("controllers.lectures.destruction_failed_prerequisite") if required_elsewhere

      t("controllers.lectures.destruction_failed")
    end

    # destroy all notifications related to this lecture
    def destroy_notifications
      Notification.where(notifiable_id: @lecture.id, notifiable_type: "Lecture")
                  .delete_all
    end

    # fill organizational_concept with default view
    def set_organizational_defaults
      partial_path = "lectures/organizational/defaults/"
      partial_path += @lecture.seminar? ? "seminar" : "lecture"
      @lecture.update(organizational_concept:
                        render_to_string(partial: partial_path,
                                         formats: :html,
                                         layout: false))
    end

    # set language to default language
    def set_language
      @lecture.update(locale: I18n.default_locale.to_s)
    end

    def eager_load_stuff
      @lecture = Lecture.includes(:teacher, :term, :editors,
                                  :announcements, :imported_media,
                                  course: [:editors],
                                  media: [:teachable, :tags],
                                  lessons: [media: [:tags]],
                                  chapters: [:lecture,
                                             { sections: [lessons: [:tags],
                                                          chapter: [:lecture],
                                                          tags: [:notions,
                                                                 :lessons]] }])
                        .find_by(id: params[:id])
      @media = @lecture.media_with_inheritance_uncached_eagerload_stuff
      @announcements = @lecture.announcements.includes(:announcer).order(:created_at).reverse
      @terms = Term.select_terms
    end

    def search_params
      params.expect(search: [:all_types, :all_terms, :all_programs,
                             :all_teachers, :fulltext, :per, :term,
                             { types: [],
                               term_ids: [],
                               program_ids: [],
                               teacher_ids: [] }])
    end

    def check_if_enough_questions
      return if @lecture.course.enough_questions?

      redirect_to :root, alert: I18n.t("controllers.no_test")
    end

    # Reads the new editors before the update, which makes them editors already.
    def editors_to_notify
      editor_ids = lecture_params[:editor_ids]
      return User.none if editor_ids.nil?

      all_ids = editor_ids.map(&:to_i) - [0]
      User.where(id: all_ids - @lecture.editor_ids).to_a
    end

    def notify_new_editors(recipients)
      recipients.each { |r| LectureNotifier.notify_new_editor_by_mail(r, @lecture) }
    end

    # Caches the form's file through the malware scan; the attacher refuses it
    # as a mass-assigned attribute.
    def attach_scanned_home_attachment
      upload = permitted_lecture_params[:home_attachment]
      return if upload.blank?
      raise(ActionController::BadRequest) unless upload.respond_to?(:tempfile)

      File.open(upload.tempfile.path) do |file|
        @lecture.home_attachment_attacher.attach_cached(
          file, metadata: { "filename" => upload.original_filename }
        )
      end
    end

    # Hands the typed intro back unsaved: the scan refuses before the update
    # would have assigned it.
    def refuse_home_attachment(message)
      @lecture.assign_attributes(lecture_params.slice(:home_intro))
      @lecture.errors.add(:home_attachment, message)
      handle_failed_update
    end

    # Touches only after a successful update: a touch after a failed one still
    # commits, and promotes the attachment the validation refused.
    def update_lecture_and_forum
      if @lecture.update(lecture_params)
        @lecture.touch
        @lecture.forum&.update(name: @lecture.forum_title)
      end
      @errors = @lecture.errors
    end

    def handle_update_response
      if @lecture.valid?
        handle_successful_update
      else
        handle_failed_update
      end
    end

    def handle_successful_update
      respond_to do |format|
        format.html { redirect_to_edit_lecture }
        format.turbo_stream { render_turbo_stream_update }
      end
    end

    def redirect_to_edit_lecture
      if params[:subpage].present?
        redirect_to edit_lecture_path(@lecture, tab: params[:subpage])
      else
        redirect_to edit_lecture_path(@lecture)
      end
    end

    # Only the assessments pane has something to put in place of itself. Every
    # other tab is answered the way a form submit is answered without Turbo --
    # by loading the tab again; rendering nothing leaves the page as it was and
    # the save looks like it did not happen.
    def render_turbo_stream_update
      return redirect_to_edit_lecture unless params[:subpage] == "assessments"

      flash.now[:notice] = t("admin.lecture.updated")
      streams = [
        turbo_stream.replace(
          "lecture-submission-settings",
          partial: "assessment/assessments/submission_settings",
          locals: { lecture: @lecture }
        )
      ]
      streams << stream_flash if flash.present?
      render turbo_stream: streams
    end

    def handle_failed_update
      @terms = Term.select_terms

      pane, partial = case params[:subpage]
                      when "people" then ["edit_people", "lectures/edit/people"]
                      when "home" then ["edit_home", "lectures/edit/home"]
                      else ["edit_preferences", "lectures/edit/preferences"]
      end

      render turbo_stream: turbo_stream.update(pane, partial: partial,
                                                     locals: { lecture: @lecture }),
             status: :unprocessable_content
    end
end
