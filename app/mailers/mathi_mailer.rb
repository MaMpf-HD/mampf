class MathiMailer < ApplicationMailer
  default from: DefaultSetting::FROM_ADDRESS
  layout false

  def data_provide_email(user)
    @user = user
    mail(to: user.email,
         subject: t("mailer.data_provide_mail_subject")) do |format|
      format.html { render layout: "mailer" }
    end
  end
end
