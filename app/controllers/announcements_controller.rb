class AnnouncementsController < ApplicationController
  layout "administration"
  before_action :set_announcement, only: :update
  authorize_resource only: :update

  def current_ability
    @current_ability ||= AnnouncementAbility.new(current_user)
  end

  def index
    authorize! :index, Announcement.new
    @pagy, @announcements = pagy(Announcement.where(lecture: nil)
                                             .order(created_at: :desc),
                                 limit: 10)
  end

  def new
    @lecture = Lecture.find_by(id: params[:lecture])
    @announcement = Announcement.new(announcer: current_user, lecture: @lecture)
    authorize! :new, @announcement
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.announcer = current_user
    # announcements without a lecture only feed the banner above the navbar,
    # so publishing one puts it up right away
    @announcement.on_main_page = @announcement.lecture.nil?
    authorize! :create, @announcement

    if @announcement.lecture.nil?
      create_site_announcement
    else
      create_lecture_announcement
    end
  end

  # Switches a site-wide announcement's banner on or off.
  def update
    @announcement.update(params.expect(announcement: [:on_main_page]))
    render turbo_stream: [
      turbo_stream.replace(@announcement,
                           partial: "announcements/row",
                           locals: { announcement: @announcement }),
      banner_stream
    ]
  end

  private

    def announcement_params
      params.expect(announcement: [:details, :lecture_id])
    end

    # Adds the published announcement on top of the admin list and puts up the
    # banner, or shows the inline form again with its errors.
    def create_site_announcement
      unless @announcement.save
        render :new, status: :unprocessable_content
        return
      end

      render turbo_stream: [
        turbo_stream.update("new_announcement", ""),
        turbo_stream.remove("no-announcements"),
        turbo_stream.prepend("announcements",
                             partial: "announcements/row",
                             locals: { announcement: @announcement }),
        banner_stream
      ]
    end

    # Notifies the lecture's audience and goes back to the lecture's
    # communication tab, or lets create.coffee show the errors in the modal.
    def create_lecture_announcement
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

    def banner_stream
      turbo_stream.replace("site-announcement-banner",
                           partial: "shared/announcement_banner")
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

    def set_announcement
      @announcement = Announcement.find_by(id: params[:id])
      return if @announcement.present?

      redirect_to :root, alert: I18n.t("controllers.no_announcement")
    end
end
