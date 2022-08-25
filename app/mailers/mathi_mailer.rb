class MathiMailer < ApplicationMailer
  default from: DefaultSetting::PROJECT_EMAIL
  layout false

  def ghost_email(user)
    return if user.ghost_hash.nil?
    @email = user.email
    @hash = user.ghost_hash
    mail(to: user.email, subject: "Ghost:#{@email}")
  end
end
