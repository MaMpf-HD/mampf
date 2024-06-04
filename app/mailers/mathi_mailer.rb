class MathiMailer < ApplicationMailer
  default from: DefaultSetting::PROJECT_EMAIL
  layout false

  def data_request_email(user)
    @mail = user.email
    @id = user.id
    mail(to: DefaultSetting::PROJECT_EMAIL, subject: t("mailer.data_provide_mail_subject"))
  end

  def data_provide_email(user)
    @user = user
    mail(to: user.email,
         subject: t("mailer.data_provide_mail_subject")) do |format|
      format.html { render layout: "mailer" }
    end
  end
end
