class NotificationMailer < ApplicationMailer
  def medium_email
    @recipients = params[:recipients]
    @medium = params[:medium]
    I18n.locale = params[:locale]
    mail(bcc: @recipients.pluck(:email),
         subject: t('mailer.notification') + ': ' +
                  t('mailer.medium_subject') + ' ' + t('in') + ' ' +
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
    mail(bcc: @recipients.pluck(:email),
         subject: t('mailer.notification') + ': ' +
                  t('mailer.announcement_subject') + ' ' +
                  @announcement_details)
  end
end
