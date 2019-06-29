# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, except: [:new, :create]
  authorize_resource
  before_action :check_for_consent
  before_action :set_view_locale, only: [:edit, :show, :inspect]
  layout 'administration'

  def edit
    @announcements = @lecture.announcements.order(:created_at).reverse
  end

  def inspect
    @announcements = @lecture.announcements.order(:created_at).reverse
  end

  def update
    @lecture.update(lecture_params)
    redirect_to edit_lecture_path(@lecture) if @lecture.valid?
    @errors = @lecture.errors
  end

  def show
    cookies[:current_course] = @lecture.course.id
    cookies[:current_lecture] = @lecture.id
    render layout: 'application'
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

  def render_sidebar
    @course = @lecture.course
  end

  # add forum for this lecture
  def add_forum
    Thredded::Messageboard.create(name: @lecture.title) unless @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
  end

  # lock forum for this lecture
  def lock_forum
    @lecture.forum.update(locked: true) if @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
  end

  # unlock forum for this lecture
  def unlock_forum
    @lecture.forum.update(locked: false) if @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
  end

  # destroy forum for this lecture
  def destroy_forum
    @lecture.forum.destroy if @lecture.forum?
    redirect_to edit_lecture_path(@lecture)
  end

  # show all announcements for this lecture
  def show_announcements
    @announcements = @lecture.announcements.order(:created_at).reverse
    I18n.locale = @lecture.locale_with_inheritance
    render layout: 'application'
  end

  def organizational
    cookies[:current_lecture] = @lecture.id
    cookies[:current_course] = @lecture.course.id
    I18n.locale = @lecture.locale_with_inheritance
    render layout: 'application'
  end

  private

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    return if @lecture.present?
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
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
                                    :content_mode, :passphrase,
                                    editor_ids: [])
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
        NotificationMailer.with(recipients: local_recipients,
                                locale: l,
                                lecture: @lecture)
                          .new_lecture_email.deliver_now
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
    @lecture.update(organizational_concept:
                      render_to_string(partial: 'lectures/' \
                                                'organizational_default',
                                       formats: :html,
                                       layout: false))
  end

  # set language to default language
  def set_language
    @lecture.update(locale: I18n.default_locale.to_s)
  end
end
