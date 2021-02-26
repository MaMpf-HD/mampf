class MediumPublisher
  attr_reader :medium_id, :release_for, :release_date, :lock_comments,
              :vertices, :user_id

  def initialize(medium_id:, release_for: 'all', release_date: nil,
                 lock_comments: false, vertices: false, user_id:)
    @medium_id = medium_id
    @release_for = release_for
    @release_date = release_date
    @lock_comments = lock_comments
    @vertices = vertices
    @user_id = user_id
  end

  def self.load(text)
    YAML.load(text) if text.present?
  end

  def self.dump(medium_publisher)
    medium_publisher.to_yaml
  end

  def publish!
    @medium = Medium.find_by_id(@medium_id)
    user = User.find_by_id(@user_id)
    return unless @medium && user
    return unless @medium.edited_by?(user) || user.admin
    @medium.update(released: @release_for, released_at: Time.now)
    @medium.commontator_thread.close(user) if @lock_comments
    if @medium.sort == 'Quiz' && @vertices
      @medium.becomes(Quiz).publish_vertices!(user, @release_for)
    end
    return true if @medium.sort.in?(['Question', 'Remark', 'RandomQuiz'])
    # create notification about creation of medium to all subscribers
    # and send an email
    @medium.teachable&.media_scope&.touch
    create_notifications
    send_notification_email
    true
  end

  private

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
end