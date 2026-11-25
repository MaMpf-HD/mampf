# Announcements in a lecture, which notify the lecture's audience. Site-wide
# announcements are handled by SiteAnnouncementsController.
class AnnouncementsController < ApplicationController
  def current_ability
    @current_ability ||= AnnouncementAbility.new(current_user)
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
    unless @announcement.save
      @errors = @announcement.errors[:details].join(", ")
      return
    end

    # trigger creation of notifications for all relevant users
    create_notifications
    # send notification email
    send_notification_email
    redirect_to edit_lecture_path(@announcement.lecture, tab: "communication")
  end

  private

    def announcement_params
      params.expect(announcement: [:details, :lecture_id])
    end

    def create_notifications
      users_to_notify = @announcement.lecture.audience
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
      recipients = @announcement.lecture.audience
                                .where(email_for_announcement: true)
      I18n.available_locales.each do |l|
        local_recipients = recipients.where(locale: l)
        next unless local_recipients.any?

        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                announcement: @announcement)
                          .announcement_email.deliver_later
      end
    end
end
