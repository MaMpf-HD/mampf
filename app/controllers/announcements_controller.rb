# AnnouncementsController
class AnnouncementsController < ApplicationController
  authorize_resource
  layout 'administration'
  before_action :set_announcement, only: [:propagate, :expel]

  def index
    @announcements = Kaminari.paginate_array(Announcement.where(lecture: nil)
                                                         .order(:created_at)
                                                         .reverse)
                             .page(params[:page]).per(10)
  end

  def new
    @lecture = Lecture.find_by_id(params[:lecture])
    @announcement = Announcement.new(announcer: current_user, lecture: @lecture)
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.announcer = current_user
    @announcement.save
    if @announcement.valid?
      # trigger creation of notifications for all relevant users
      create_notifications
      # send notification email
      send_notification_email
      # redirection depending from where the announcement was created
      unless @announcement.lecture.present?
        redirect_to announcements_path
        return
      end
      redirect_to edit_lecture_path(@announcement.lecture)
      return
    end
    @errors = @announcement.errors[:details].join(', ')
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
    params.require(:announcement).permit(:details, :lecture_id, :on_main_page)
  end

  def create_notifications
    users_to_notify = if @announcement.lecture.present?
                        @announcement.lecture.users
                      else
                        User
                      end
    notifications = []
    users_to_notify.update_all(updated_at: Time.now)
    users_to_notify.find_each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @announcement.id,
                                        notifiable_type: 'Announcement',
                                        action: 'create')
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
      if local_recipients.any?
        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                announcement: @announcement)
                          .announcement_email.deliver_later
      end
    end
  end

  def set_announcement
    @announcement = Announcement.find_by_id(params[:id])
    return if @announcement.present?
    redirect_to :root, alert: I18n.t('controllers.no_announcement')
  end
end
