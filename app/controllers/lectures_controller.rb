# LecturesController
class LecturesController < ApplicationController
  include ActionController::RequestForgeryProtection
  before_action :set_lecture, except: [:new, :create, :search]
  before_action :set_lecture_cookie, only: [:show, :organizational,
                                            :show_announcements]
  before_action :set_erdbeere_data, only: [:show_structures, :edit_structures]
  authorize_resource
  before_action :check_for_consent
  before_action :set_view_locale, only: [:edit, :show, :inspect,
                                         :show_random_quizzes]
  before_action :check_if_enough_questions, only: [:show_random_quizzes]
  layout 'administration'

  def edit
    if stale?(etag: @lecture,
              last_modified: [current_user.updated_at, @lecture.updated_at,
                              Time.parse(ENV['RAILS_CACHE_ID'])].max)
      eager_load_stuff
    end
  end

  def inspect
    if stale?(etag: @lecture,
              last_modified: [current_user.updated_at, @lecture.updated_at,
                              Time.parse(ENV['RAILS_CACHE_ID'])].max)
      eager_load_stuff
    end
  end

  def update
    @lecture.update(lecture_params)
    if structure_params.present?
      structure_ids = structure_params.select { |_k, v| v.to_i == 1 }.keys
                        .map(&:to_i)
      @lecture.update(structure_ids: structure_ids)
    end
    @lecture.touch
    @lecture.forum&.update(name: @lecture.forum_title)
    redirect_to edit_lecture_path(@lecture) if @lecture.valid?
    @errors = @lecture.errors
  end

  def show
    # deactivate http caching for the moment
    if stale?(etag: @lecture,
              last_modified: [current_user.updated_at,
                              @lecture.updated_at,
                              Time.parse(ENV['RAILS_CACHE_ID']),
                              Thredded::UserDetail.find_by(user_id: current_user.id)
                                                  &.last_seen_at || @lecture.updated_at,
                              @lecture.forum&.updated_at || @lecture.updated_at].max)
      @lecture = Lecture.includes(:teacher, :term, :editors, :users,
                                  :announcements, :imported_media,
                                  course: [:editors],
                                  media: [:teachable, :tags],
                                  lessons: [media: [:tags]],
                                  chapters: [:lecture,
                                             sections: [lessons: [:tags],
                                                        chapter: [:lecture],
                                                        tags: [:notions, :lessons]]])
                        .find_by_id(params[:id])
      @notifications = current_user.active_notifications(@lecture)
      @new_topics_count = @lecture.unread_forum_topics_count(current_user) || 0
      render layout: 'application'
    end
  end

  def new
    @lecture = Lecture.new
    @from = params[:from]
    return unless @from == 'course'
    # if new action was triggered from inside a course view, add the course
    # info to the lecture
    @lecture.course = Course.find_by_id(params[:course])
    I18n.locale = @lecture.course.locale
  end

  def create
    @lecture = Lecture.new(lecture_params)
    @lecture.save
    if @lecture.valid?
      @lecture.update(sort: 'special') if @lecture.course.term_independent
      # set organizational_concept to default
      set_organizational_defaults
      # set lenguage to default language
      set_language
      # depending on where the create action was trriggered from, return
      # to admin index view or edit course view
      unless params[:lecture][:from] == 'course'
        redirect_to administration_path
        return
      end
      redirect_to edit_course_path(@lecture.course)
      return
    end
    @errors = @lecture.errors
  end

  def publish
    @lecture.update(released: 'all')
    if params[:medium][:publish_media] == '1'
      @lecture.media_with_inheritance
              .update_all(released: params[:medium][:released])
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
    redirect_to edit_lecture_path(@lecture)
  end

  # lock forum for this lecture
  def lock_forum
    @lecture.forum.update(locked: true) if @lecture.forum?
    @lecture.touch
    redirect_to edit_lecture_path(@lecture)
  end

  # unlock forum for this lecture
  def unlock_forum
    @lecture.forum.update(locked: false) if @lecture.forum?
    @lecture.touch
    redirect_to edit_lecture_path(@lecture)
  end

  # destroy forum for this lecture
  def destroy_forum
    @lecture.forum.destroy if @lecture.forum?
    @lecture.update(forum_id: nil)
    redirect_to edit_lecture_path(@lecture)
  end

  # show all announcements for this lecture
  def show_announcements
    @announcements = @lecture.announcements.order(:created_at).reverse
    @active_notification_count = current_user.active_notifications(@lecture)
                                             .size
    I18n.locale = @lecture.locale_with_inheritance
    render layout: 'application'
  end

  def organizational
    I18n.locale = @lecture.locale_with_inheritance
    render layout: 'application'
  end

  def import_media
    media = Medium.where(id: params[:media_ids])
                  .where.not(id: @lecture.imported_media.pluck(:id))
                  .where.not(teachable: @lecture)
    media.each { |m| Import.create(teachable: @lecture, medium: m) }
    @lecture.reload
    @lecture.touch
  end

  def remove_imported_medium
    @medium = Medium.find_by_id(params[:medium])
    import = Import.find_by(teachable: @lecture, medium: @medium)
    import.destroy if import
    @lecture.reload
    @lecture.touch
  end

  def show_subscribers
    user_data = @lecture.users.pluck(:name, :email)
    render json: user_data
  end

  def show_structures
    render layout: 'application'
  end

  def edit_structures
    render layout: 'application'
  end

  def search_examples
    if @lecture.structure_ids.any?
      response = Faraday.get(ENV['ERDBEERE_API'] + '/search')
      @form = JSON.parse(response.body)['embedded_html']
      @form.gsub!('token_placeholder',
                  '<input type="hidden" name="authenticity_token" ' +
                  'value="' + form_authenticity_token + '">')
    else
      @form = I18n.t('erdbeere.no_structures')
    end
    render layout: 'application'
  end

  def close_comments
    @lecture.close_comments!(current_user)
    redirect_to edit_lecture_path(@lecture)
  end

  def open_comments
    @lecture.open_comments!(current_user)
    redirect_to edit_lecture_path(@lecture)
  end

  def search
    search = Lecture.search_by(search_params, params[:page])
    search.execute
    results = search.results
    @total = search.total
    @lectures = Kaminari.paginate_array(results, total_count: @total)
                        .page(params[:page]).per(search_params[:per])
    return unless @total.zero?
    return unless search_params[:fulltext]&.length.to_i > 1
    @similar_titles = Course.similar_courses(search_params[:fulltext])
  end

  def show_random_quizzes
    @course = @lecture.course
    render layout: 'application'
  end

  def display_course
    @course = @lecture.course
    I18n.locale = @course.locale || @lecture.locale
    render layout: 'application'
  end

  private

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def set_lecture_cookie
    cookies[:current_lecture_id] = strict_cookie(@lecture.id)
  end

  def set_view_locale
    I18n.locale = @lecture.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def lecture_params
    params.require(:lecture).permit(:course_id, :term_id, :teacher_id,
                                    :start_chapter, :absolute_numbering,
                                    :start_section, :organizational, :locale,
                                    :organizational_concept, :muesli,
                                    :organizational_on_top,
                                    :disable_teacher_display,
                                    :content_mode, :passphrase, :sort,
                                    :comments_disabled,
                                    :submission_max_team_size,
                                    :submission_grace_period,
                                    editor_ids: [])
  end

  def structure_params
    params.require(:lecture).permit(structures: {})[:structures]
  end

  def comment_params
    params.require(:lecture).permit(:close_comments)
  end

  # create notifications to all users about creation of new lecture
  def create_notifications
    notifications = []
    User.find_each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @lecture.id,
                                        notifiable_type: 'Lecture',
                                        action: 'create')
    end
    Notification.import notifications
  end

  def send_notification_email
    recipients = User.where(email_for_teachable: true)
    I18n.available_locales.each do |l|
      local_recipients = recipients.where(locale: l)
      if local_recipients.any?
        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                lecture: @lecture)
                          .new_lecture_email.deliver_later
      end
    end
  end

  # destroy all notifications related to this lecture
  def destroy_notifications
    Notification.where(notifiable_id: @lecture.id, notifiable_type: 'Lecture')
                .delete_all
  end

  # fill organizational_concept with default view
  def set_organizational_defaults
    partial_path = 'lectures/organizational/'
    partial_path += @lecture.seminar? ? 'seminar' : 'lecture'
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
                                           sections: [lessons: [:tags],
                                                      chapter: [:lecture],
                                                      tags: [:notions, :lessons]]])
                      .find_by_id(params[:id])
    @media = @lecture.media_with_inheritance_uncached_eagerload_stuff
    lecture_tags = @lecture.tags
    @course_tags = @lecture.course_tags(lecture_tags: lecture_tags)
    @extra_tags = @lecture.extra_tags(lecture_tags: lecture_tags)
    @deferred_tags = @lecture.deferred_tags(lecture_tags: lecture_tags)
    @announcements = @lecture.announcements.includes(:announcer).order(:created_at).reverse
    @terms = Term.select_terms
  end

  def set_erdbeere_data
    @structure_ids = @lecture.structure_ids
    response = Faraday.get(ENV['ERDBEERE_API'] + '/structures')
    response_hash = if response.status == 200
                       JSON.parse(response.body)
                     else
                       { 'data' => {}, 'included' => {} }
                     end
    @all_structures = response_hash['data']
    @structures = @all_structures.select do |s|
      s['id'].to_i.in?(@structure_ids)
    end
    @properties = response_hash['included']
  end

  def search_params
    types = params[:search][:types]
    types = [types] if types && !types.kind_of?(Array)
    types -= [''] if types
    types = nil if types == []
    params[:search][:types] = types
    params[:search][:user_id] = current_user.id
    params.require(:search).permit(:all_types, :all_terms, :all_programs,
                                   :all_teachers, :fulltext, :per, :user_id,
                                   types: [],
                                   term_ids: [],
                                   program_ids: [],
                                   teacher_ids: [])
  end

  def check_if_enough_questions
    return if @lecture.course.enough_questions?
    redirect_to :root, alert: I18n.t('controllers.no_test')
  end
end
