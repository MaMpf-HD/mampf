# MainController
class MainController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :about, :news,
                                                 :sponsors]
  before_action :check_for_consent
  authorize_resource class: false, only: :start
  layout 'application_no_sidebar'

  def home
    if user_signed_in?
      cookies[:locale] = current_user.locale
    end
    @announcements = Announcement.where(on_main_page: true,
                                        lecture: nil).pluck(:details).join
  end

  def error
    redirect_to :root, alert: I18n.t('controllers.no_page')
  end

  def news
    @announcements = Announcement.where(lecture: nil).order(:created_at)
                                 .reverse
  end

  def sponsors
  end

  def comments
    @media_comments = current_user.media_latest_comments
    @media_comments.select! do |m|
      (Reader.find_by(user: current_user, thread: m[:thread])
            &.updated_at || (Time.now - 1000.years)) < m[:latest_comment].created_at
    end
    @media_array = Kaminari.paginate_array(@media_comments)
                           .page(params[:page]).per(10)
  end

  def start
    @current_stuff = current_user.current_subscribed_lectures
    if @current_stuff.empty?
      @inactive_lectures = current_user.inactive_lectures.includes(:course,
                                                                   :term)
                                       .sort
    end
    @announcements = Announcement.where(on_main_page: true,
                                        lecture: nil).pluck(:details).join
    @talks = current_user.talks.includes(lecture: :term)
                         .select { |t| t.visible_for_user?(current_user) }
                         .sort_by do |t|
                            [-t.lecture.term.begin_date.jd,
                             t.position]
                         end
  end

  def test_mail
    #response = NotificationMailer.with(recipients: [580],#, 581, 582, 583, 584],
    #                        locale: "de")
    #                  .test_email.deliver_now!
    logger = Logger.new("log/emails.log")
    logger.info('Trying to read emails:')
    logger.info("Email: #{ENV['PROJECT_EMAIL']}")
    imap = Net::IMAP.new(ENV['IMAPSERVER'])
    imap.authenticate('LOGIN', ENV['PROJECT_EMAIL_USERNAME'], ENV['PROJECT_EMAIL_PASSWORD'])
    imap.examine('PROJECT_EMAIL_MAILBOX')
    imap.search(["RECENT"]).each do |message_id|
      envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
      logger.info("#{envelope.from[0].name}: \t#{envelope.subject}")
    end
    redirect_to administration_path
  end

  private

  def check_for_consent
    return unless user_signed_in?
    redirect_to consent_profile_path unless current_user.consents
  end
end
