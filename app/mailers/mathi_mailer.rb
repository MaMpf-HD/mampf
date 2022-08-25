class MathiMailer < ApplicationMailer
  default from: DefaultSetting::PROJECT_EMAIL
  layout false

  def ghost_email(user)
    return if user.ghost_hash.nil?
    @name = user.name
    @hash = user.ghost_hash
    mail(to: user.email, subject: t('mailer.hash_mail_subject'))
  end
end
