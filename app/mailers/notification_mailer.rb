class NotificationMailer < ApplicationMailer
  def medium_email
    @recipients = params[:recipients]
    @medium = params[:medium]
    I18n.locale = params[:locale]
    mail(bcc: @recipients.pluck(:email),
         subject: "#{t('mailer.notification')}: #{t('mailer.medium_subject')}")
  end
end
