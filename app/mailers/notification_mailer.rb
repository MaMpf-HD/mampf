class NotificationMailer < ApplicationMailer
  def medium_email
    @recipients = params[:recipients]
    @medium = params[:medium]
    I18n.locale = params[:locale]
    mail(from: "#{t('mailer.notification')} <#{DefaultSetting::PROJECT_EMAIL}>",
         bcc: @recipients.pluck(:email),
         subject: t('mailer.medium_subject') + ' ' + t('in') + ' ' +
                  @medium.teachable.media_scope.title_for_viewers)
  end

  def announcement_email
    @recipients = params[:recipients]
    @announcement = params[:announcement]
    I18n.locale = params[:locale]
    @announcement_details = if @announcement.lecture.present?
                             t('in') + ' ' +
                               @announcement.lecture.title_for_viewers
                            else
                              t('mailer.mampf_news')
                            end
    mail(from: "#{t('mailer.notification')} <#{DefaultSetting::PROJECT_EMAIL}>",
         bcc: @recipients.pluck(:email),
         subject: t('mailer.announcement_subject') + ' ' +
                  @announcement_details)
  end

  def new_lecture_email
    @recipients = params[:recipients]
    @lecture = params[:lecture]
    I18n.locale = params[:locale]
    mail(from: "#{t('mailer.notification')} <#{DefaultSetting::PROJECT_EMAIL}>",
         bcc: @recipients.pluck(:email),
         subject: t('mailer.new_lecture_subject',
                    title: @lecture.title_for_viewers))
  end

  def new_course_email
    @recipients = params[:recipients]
    @course = params[:course]
    I18n.locale = params[:locale]
    mail(from: "#{t('mailer.notification')} <#{DefaultSetting::PROJECT_EMAIL}>",
         bcc: @recipients.pluck(:email),
         subject: t('mailer.new_course_subject',
                    title: @course.title))
  end
end
