# frozen_string_literal: true

# PORO class that handles the publication of media
class MediumPublisher
  attr_reader :medium_id, :user_id, :release_now, :release_for, :release_date,
              :lock_comments, :vertices, :create_assignment, :assignment_title,
              :assignment_file_type, :assignment_deadline,
              :assignment_deletion_date

  def initialize(medium_id:, user_id:, release_now:,
                 release_for: "all", release_date: nil,
                 lock_comments: false, vertices: false,
                 create_assignment: false, assignment_title: "",
                 assignment_file_type: "", assignment_deadline: nil,
                 assignment_deletion_date: nil)
    @medium_id = medium_id
    @user_id = user_id
    @release_now = release_now
    @release_for = release_for
    @release_date = release_date
    @lock_comments = lock_comments
    @vertices = vertices
    @create_assignment = create_assignment
    @assignment_title = assignment_title
    @assignment_file_type = assignment_file_type
    @assignment_deadline = assignment_deadline
    @assignment_deletion_date = assignment_deletion_date
  end

  def self.load(text)
    return if text.blank?

    YAML.safe_load(text,
                   permitted_classes: [MediumPublisher,
                                       ActiveSupport::TimeWithZone,
                                       ActiveSupport::TimeZone,
                                       DateTime,
                                       Time],
                   aliases: true)
  end

  def self.dump(medium_publisher)
    medium_publisher.to_yaml
  end

  def self.parse(medium, user, params)
    begin
      release_date = Time.zone.parse(params[:release_date] || "")
    rescue ArgumentError
      puts "Argument error for medium release date"
    end
    begin
      assignment_deadline = Time.zone.parse(params[:assignment_deadline] || "")
    rescue ArgumentError
      puts "Argument error for medium assignment deadline"
    end
    begin
      assignment_deletion_date = Time.zone.parse(params[:assignment_deletion_date] || "")
    rescue ArgumentError
      puts "Argument error for medium assignment deletion date"
    end
    MediumPublisher.new(medium_id: medium.id, user_id: user.id,
                        release_now: params[:release_now] == "1",
                        release_for: params[:released],
                        release_date: release_date,
                        lock_comments: params[:lock_comments] == "1",
                        vertices: params[:publish_vertices] == "1",
                        create_assignment: params[:create_assignment] == "1",
                        assignment_title: params[:assignment_title],
                        assignment_file_type: params[:assignment_file_type],
                        assignment_deadline: assignment_deadline,
                        assignment_deletion_date: assignment_deletion_date)
  end

  def publish!
    @medium = Medium.find_by_id(@medium_id)
    @user = User.find_by_id(@user_id)
    return unless @medium && @user && @medium.released_at.nil?
    return unless @user.can_edit?(@medium)

    update_medium!
    realize_optional_stuff!
    return true if medium_without_notifications?

    # create notification about creation of medium to all subscribers
    # and send an email
    create_notifications!
    send_notification_email!
    true
  end

  def assignment
    return unless @create_assignment

    Assignment.new(lecture: medium.teachable,
                   medium_id: @medium_id,
                   title: @assignment_title,
                   deadline: @assignment_deadline,
                   accepted_file_type: @assignment_file_type,
                   deletion_date: @assignment_deletion_date)
  end

  def errors
    return {} if @release_now && !@create_assignment

    @errors = {}
    add_release_date_error and return @errors if invalid_release_date?
    return {} unless @create_assignment

    add_assignment_deadline_error if invalid_assignment_deadline?
    add_assignment_deletion_date_error if invalid_assignment_deletion_date?
    add_assignment_title_error if invalid_assignment_title?
    @errors
  end

  private

    def update_medium!
      @medium.update(released: @release_for, released_at: Time.zone.now,
                     publisher: nil)
    end

    def realize_optional_stuff!
      close_thread! if @lock_comments
      publish_vertices! if @medium.sort == "Quiz" && @vertices
      create_assignment! if @create_assignment
    end

    # create notifications to all users who are subscribed
    # to the medium's teachable's media_scope
    def create_notifications!
      @medium.teachable&.media_scope&.touch
      notifications = []
      @medium.teachable.media_scope.users.update_all(updated_at: Time.zone.now)
      @medium.teachable.media_scope.users.each do |u|
        notifications << Notification.new(recipient: u,
                                          notifiable_id: @medium.id,
                                          notifiable_type: "Medium",
                                          action: "create")
      end
      Notification.import notifications
    end

    def send_notification_email!
      recipients = @medium.teachable.media_scope.users
                          .where(email_for_medium: true)
      I18n.available_locales.each do |l|
        local_recipients = recipients.where(locale: l)
        next unless local_recipients.any?

        NotificationMailer.with(recipients: local_recipients.pluck(:id),
                                locale: l,
                                medium: @medium)
                          .medium_email.deliver_later
      end
    end

    def medium
      Medium.find_by_id(@medium_id)
    end

    def publish_vertices!
      @medium.becomes(Quiz).publish_vertices!(@user, @release_for)
    end

    def close_thread!
      @medium.commontator_thread.close(@user)
    end

    def create_assignment!
      assignment.save
    end

    def invalid_release_date?
      !@release_now && (@release_date.nil? || @release_date <= Time.zone.now)
    end

    def invalid_assignment_deadline?
      earliest_deadline = @release_now ? Time.zone.now : @release_date
      @assignment_deadline.nil? || (@assignment_deadline < earliest_deadline)
    end

    def invalid_assignment_deletion_date?
      @assignment_deletion_date.nil? || (@assignment_deletion_date < Time.zone.today)
    end

    def invalid_assignment_title?
      @assignment_title.blank? ||
        @assignment_title.in?(Assignment.where(lecture: medium.teachable)
                                        .pluck(:title))
    end

    def add_release_date_error
      @errors[:release_date] = I18n.t("admin.medium.invalid_publish_date")
    end

    def add_assignment_deadline_error
      @errors[:assignment_deadline] = I18n.t("admin.medium" \
                                             ".invalid_assignment_deadline")
    end

    def add_assignment_deletion_date_error
      @errors[:assignment_deletion_date] = I18n.t("activerecord.errors." \
                                                  "models.assignment." \
                                                  "attributes.deletion_date." \
                                                  "in_past")
    end

    def add_assignment_title_error
      @errors[:assignment_title] = I18n.t("admin.medium" \
                                          ".invalid_assignment_title")
    end

    def medium_without_notifications?
      @medium.sort.in?(["Question", "Remark", "RandomQuiz"])
    end
end
