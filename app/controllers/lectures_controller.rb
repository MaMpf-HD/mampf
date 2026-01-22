# LecturesController
class LecturesController < ApplicationController
  include ActionController::RequestForgeryProtection

  before_action :set_lecture, except: [:new, :create, :search]
  before_action :set_lecture_cookie, only: [:show, :organizational,
                                            :show_announcements]
  authorize_resource except: [:new, :create, :search]
  before_action :check_for_consent
  before_action :check_for_subscribe, only: [:show]
  before_action :set_view_locale, only: [:edit, :show, :subscribe_page,
                                         :show_random_quizzes]
  before_action :check_if_enough_questions, only: [:show_random_quizzes]
  layout "administration"

  def current_ability
    @current_ability ||= LectureAbility.new(current_user)
  end

  def show
    if @lecture.sort == "vignettes"
      if @lecture.organizational
        redirect_to lecture_organizational_path(@lecture)
        return
      end
      redirect_to lecture_questionnaires_path(@lecture)
      return
    end

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

  def new
    @lecture = Lecture.new(sort: "lecture")
    authorize! :new, @lecture
    @from = params[:from]

    if @from == "course"
      # if new action was triggered from inside a course view, add the course
      # info to the lecture
      @lecture.course = Course.find_by(id: params[:course])
      I18n.locale = @lecture.course.locale
      @lecture.annotations_status = 0
    end

    render template: "lectures/new/_new",
           locals: { lecture: @lecture, from: @from },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def edit
    if stale?(etag: @lecture,
              last_modified: [current_user.updated_at, @lecture.updated_at,
                              Time.zone.parse(ENV.fetch("RAILS_CACHE_ID", nil))].max)
      eager_load_stuff
      render template: "lectures/edit/edit"
    end
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

      streams << if params.dig(:lecture, :from) == "course"
        turbo_stream.update("course_lectures",
                            partial: "courses/lectures_list",
                            locals: { course: @lecture.course })
      else
        turbo_stream.update("lectures",
                            partial: "administration/index/lectures_list")
      end

      streams << turbo_stream.update(Lecture.new, "")
      streams << turbo_stream.prepend("flash-messages",
                                      partial: "flash/message")

      render turbo_stream: streams
    else
      # Error case: Display validation errors
      @errors = @lecture.errors
      @from = params[:lecture][:from]

      render turbo_stream: [
        turbo_stream.update("new-lecture-course-error",
                            @errors[:course].present? ? @errors[:course].join(" ") : ""),
        turbo_stream.update("new-lecture-term-error",
                            @errors[:term].present? ? @errors[:term].join(" ") : ""),
        turbo_stream.update("lecture-teacher-error",
                            @errors[:teacher].present? ? @errors[:teacher].join(" ") : "")
      ], status: :unprocessable_content
    end
  end

  def update
    return unless @lecture.valid_annotations_status?

    editor_ids = lecture_params[:editor_ids]
    unless editor_ids.nil?
      # removes the empty String "" in the NEW array of editor ids
      # and converts it into an array of integers
      all_ids = editor_ids.map(&:to_i) - [0]
      old_ids = @lecture.editor_ids
      new_ids = all_ids - old_ids

      # returns an array of Users that match the given ids
      recipients = User.where(id: new_ids)

      recipients.each do |r|
        LectureNotifier.notify_new_editor_by_mail(r, @lecture)
      end
    end

    @lecture.update(lecture_params)
    @lecture.touch
    @lecture.forum&.update(name: @lecture.forum_title)

    @errors = @lecture.errors

    if @lecture.valid?
      if params[:subpage].present?
        redirect_to edit_lecture_path(@lecture, tab: params[:subpage])
      else
        redirect_to edit_lecture_path(@lecture)
      end
      return
    end

    respond_to do |format|
      format.js { render template: "lectures/update/update" }
    end
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
    @lecture.destroy
    # destroy all notifications related to this lecture
    destroy_notifications
    redirect_to administration_path
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
    I18n.locale = @lecture.locale_with_inheritance
    render template: "lectures/announcements/show_announcements",
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def organizational
    if @lecture.sort == "vignettes"
      render template: "lectures/organizational/_organizational",
             layout: "vignettes/layouts/vignettes_navbar",
             locals: { lecture: @lecture }
    else
      I18n.locale = @lecture.locale_with_inheritance
      render template: "lectures/organizational/_organizational",
             locals: { lecture: @lecture },
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end
  end

  def import_media
    media = Medium.where(id: params[:media_ids])
                  .where.not(id: @lecture.imported_media.pluck(:id))
                  .where.not(teachable: @lecture)
    media.each { |m| Import.create(teachable: @lecture, medium: m) }
    @lecture.reload
    @lecture.touch

    respond_to do |format|
      format.js { render template: "lectures/import/import_media" }
    end
  end

  def remove_imported_medium
    @medium = Medium.find_by(id: params[:medium])
    import = Import.find_by(teachable: @lecture, medium: @medium)
    import&.destroy
    @lecture.reload
    @lecture.touch

    respond_to do |format|
      format.js { render template: "lectures/import/remove_imported_medium" }
    end
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
            turbo_stream.append("lecture-search-results",
                                partial: "lectures/search/lecture",
                                collection: @lectures)
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
    I18n.locale = @course.locale || @lecture.locale
    render template: "lectures/course/display_course",
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def subscribe_page
    render template: "lectures/subscribe/subscribe_page",
           layout: "application_no_sidebar"
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

    def set_lecture
      @lecture = Lecture.find_by(id: params[:id])
      return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_lecture_cookie
      cookies[:current_lecture_id] = @lecture.id
    end

    def set_view_locale
      I18n.locale = @lecture.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end

    def check_for_subscribe
      return if @lecture.in?(current_user.lectures)

      redirect_to subscribe_lecture_page_path(@lecture.id)
    end

    def lecture_params
      allowed_params = [:term_id, :start_chapter, :absolute_numbering,
                        :start_section, :organizational, :locale,
                        :organizational_concept, :muesli,
                        :organizational_on_top, :disable_teacher_display,
                        :content_mode, :passphrase, :sort, :comments_disabled,
                        :submission_max_team_size, :submission_grace_period,
                        :annotations_status]
      if action_name == "update" && current_user.can_update_personell?(@lecture)
        allowed_params.push({ editor_ids: [] })
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
                             :all_teachers, :fulltext, :per,
                             { types: [],
                               term_ids: [],
                               program_ids: [],
                               teacher_ids: [] }])
    end

    def check_if_enough_questions
      return if @lecture.course.enough_questions?

      redirect_to :root, alert: I18n.t("controllers.no_test")
    end
end
