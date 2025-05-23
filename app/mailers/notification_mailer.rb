class NotificationMailer < ApplicationMailer
  before_action :set_sender_and_locale
  before_action :set_recipients, only: [:medium_email, :announcement_email,
                                        :new_lecture_email,
                                        :submission_deletion_email,
                                        :submission_deletion_lecture_email,
                                        :submission_destruction_email,
                                        :submission_destruction_lecture_email]
  before_action :set_recipient_and_submission,
                only: [:submission_upload_email,
                       :submission_upload_removal_email,
                       :submission_join_email,
                       :submission_leave_email,
                       :correction_upload_email,
                       :submission_acceptance_email,
                       :submission_rejection_email]
  before_action :set_filename,
                only: [:submission_upload_email,
                       :submission_upload_removal_email]
  before_action :set_user,
                only: [:submission_join_email,
                       :submission_leave_email]

  def medium_email
    @medium = params[:medium]
    subject = t("mailer.medium_subject")
    viewer_title = @medium.teachable.media_scope.title_for_viewers
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: "#{subject} #{t("in")} #{viewer_title}")
  end

  def announcement_email
    @announcement = params[:announcement]
    @announcement_details = if @announcement.lecture.present?
      "#{t("in")} #{@announcement.lecture.title_for_viewers}"
    else
      t("mailer.mampf_news")
    end
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: "#{t("mailer.announcement_subject")} #{@announcement_details}")
  end

  def new_lecture_email
    @lecture = params[:lecture]
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t("mailer.new_lecture_subject",
                    title: @lecture.title_for_viewers))
  end

  def submission_invitation_email
    @recipient = params[:recipient]
    @assignment = params[:assignment]
    @code = params[:code]
    @issuer = params[:issuer]
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_invitation_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_upload_email
    @uploader = params[:uploader]
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_upload_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_upload_removal_email
    @remover = params[:remover]
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_upload_removal_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_join_email
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_join_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title,
                    user: @user.tutorial_name))
  end

  def submission_leave_email
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_leave_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title,
                    user: @user.tutorial_name))
  end

  def correction_upload_email
    @tutor = params[:tutor]
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.correction_upload_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_acceptance_email
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_acceptance_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_rejection_email
    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.submission_rejection_subject",
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_deletion_email
    @deletion_date = params[:deletion_date]
    @lectures = params[:lectures]
    subject = params[:reminder] ? "#{t("basics.reminder")}: " : ""
    subject += t("mailer.submission_deletion_subject")
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: subject)
  end

  def submission_deletion_lecture_email
    @lecture = params[:lecture]
    @deletion_date = params[:deletion_date]
    subject = params[:reminder] ? "#{t("basics.reminder")}: " : ""
    subject += t("mailer.submission_deletion_lecture_subject",
                 lecture: @lecture.title)
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: subject)
  end

  def submission_destruction_email
    @deletion_date = params[:deletion_date]
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t("mailer.submission_destruction_subject",
                    deletion_date: @deletion_date.strftime(I18n.t("date.formats.concise"))))
  end

  def submission_destruction_lecture_email
    @lecture = params[:lecture]
    @deletion_date = params[:deletion_date]
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t("mailer.submission_destruction_lecture_subject",
                    lecture: @lecture.title))
  end

  def self.sender(locale)
    I18n.t("mailer.notification", locale: locale) \
      +" <#{DefaultSetting::PROJECT_NOTIFICATION_EMAIL}>"
  end

  private

    # This method should be replaced by the one above (self.sender).
    # It only stays here during the transition phase where this file is split
    # into multiple files regarding concerns like vouchers, submissions, etc.
    def set_sender_and_locale
      @sender = "#{t("mailer.notification")} <#{DefaultSetting::PROJECT_NOTIFICATION_EMAIL}>"
      I18n.locale = params[:locale]
    end

    def set_recipients
      @recipients = User.where(id: params[:recipients])
    end

    def set_recipient_and_submission
      @recipient = params[:recipient]
      @submission = params[:submission]
      @assignment = @submission.assignment
    end

    def set_filename
      @filename = params[:filename]
    end

    def set_user
      @user = params[:user]
    end
end
