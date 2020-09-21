class NotificationMailer < ApplicationMailer
  before_action :set_sender_and_locale
  before_action :set_recipients, except: [:submission_invitation_email,
                                          :submission_upload_email,
                                          :submission_upload_removal_email]
  before_action :set_recipient_and_submission,
                only: [:submission_upload_email,
                       :submission_upload_removal_email]

  def medium_email
    @medium = params[:medium]
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t('mailer.medium_subject') + ' ' + t('in') + ' ' +
                  @medium.teachable.media_scope.title_for_viewers)
  end

  def announcement_email
    @announcement = params[:announcement]
    @announcement_details = if @announcement.lecture.present?
                             t('in') + ' ' +
                               @announcement.lecture.title_for_viewers
                            else
                              t('mailer.mampf_news')
                            end
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t('mailer.announcement_subject') + ' ' +
                  @announcement_details)
  end

  def new_lecture_email
    @lecture = params[:lecture]
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t('mailer.new_lecture_subject',
                    title: @lecture.title_for_viewers))
  end

  def new_course_email
    @course = params[:course]
    mail(from: @sender,
         bcc: @recipients.pluck(:email),
         subject: t('mailer.new_course_subject',
                    title: @course.title))
  end

  def submission_invitation_email
    @recipient = params[:recipient]
    @assignment = params[:assignment]
    @code = params[:code]
    @issuer = params[:issuer]
    mail(from: @sender,
         to: @recipient.email,
         subject: t('mailer.submission_invitation_subject',
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_upload_email
    @uploader = params[:uploader]
    mail(from: @sender,
         to: @recipient.email,
         subject: t('mailer.submission_upload_subject',
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  def submission_upload_removal_email
    @remover = params[:remover]
    mail(from: @sender,
         to: @recipient.email,
         subject: t('mailer.submission_upload_removal_subject',
                    assignment: @assignment.title,
                    lecture: @assignment.lecture.short_title))
  end

  private

  def set_sender_and_locale
    @sender = "#{t('mailer.notification')} <#{DefaultSetting::PROJECT_EMAIL}>"
    I18n.locale = params[:locale]
  end

  def set_recipients
    @recipients = params[:recipients]
  end

  def set_recipient_and_submission
    @recipient = params[:recipient]
    @submission = params[:submission]
    @filename = params[:filename]
    @assignment = @submission.assignment
  end
end
