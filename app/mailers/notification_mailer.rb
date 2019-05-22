class NotificationMailer < ApplicationMailer
  before_action :set_up

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

  private

  def set_up
    I18n.locale = params[:locale]
    @recipients = params[:recipients]
    @sender = "#{t('mailer.notification')} <#{DefaultSetting::PROJECT_EMAIL}>"
  end
end
