# AnnouncementsController
class AnnouncementsController < ApplicationController
  layout "administration"
  before_action :set_announcement, except: [:new, :create, :index]
  authorize_resource except: [:new, :create, :index]

  def current_ability
    @current_ability ||= AnnouncementAbility.new(current_user)
  end

  def index
    authorize! :index, Announcement.new
    @announcements = Kaminari.paginate_array(Announcement.where(lecture: nil)
                                                         .order(:created_at)
                                                         .reverse)
                             .page(params[:page]).per(10)
  end

  def new
    @lecture = Lecture.find_by(id: params[:lecture])
    @announcement = Announcement.new(announcer: current_user, lecture: @lecture)
    authorize! :new, @announcement
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.announcer = current_user
    authorize! :create, @announcement
    @announcement.save
    if @announcement.valid?
      # trigger creation of notifications for all relevant users
      create_notifications
      # send notification email
      send_notification_email
      # redirection depending from where the announcement was created
      if @announcement.lecture.blank?
        redirect_to announcements_path
        return
      end
      redirect_to "#{edit_lecture_path(@announcement.lecture)}#communication"
      return
    end
    @errors = @announcement.errors[:details].join(", ")
  end

  def propagate
    @announcement.update(on_main_page: true)
    redirect_to announcements_path
  end

  def expel
    @announcement.update(on_main_page: false)
    redirect_to announcements_path
  end

  private

    def announcement_params
      params.expect(announcement: [:details, :lecture_id, :on_main_page])
    end

    def create_notifications
      users_to_notify = if @announcement.lecture.present?
        @announcement.lecture.users
      else
        User
      end
      notifications = []
      users_to_notify.touch_all
      users_to_notify.find_each do |u|
        notifications << Notification.new(recipient: u,
                                          notifiable_id: @announcement.id,
                                          notifiable_type: "Announcement",
                                          action: "create")
      end
      # use activerecord-import gem to use only one SQL instruction
      Notification.import notifications
    end

    def send_notification_email
      recipients = if @announcement.lecture.present?
        @announcement.lecture.users
                     .where(email_for_announcement: true)
      else
        User.where(email_for_news: true)
      end
      I18n.available_locales.each do |l|
        local_recipients = recipients.where(locale: l)
        next unless local_recipients.any?

        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                announcement: @announcement)
                          .announcement_email.deliver_later
      end
    end

    def set_announcement
      @announcement = Announcement.find_by(id: params[:id])
      return if @announcement.present?

      redirect_to :root, alert: I18n.t("controllers.no_announcement")
    end
end
