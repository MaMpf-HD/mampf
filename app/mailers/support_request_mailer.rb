# Mails a message from the support button to the support address; the answer
# goes to whoever wrote it.
class SupportRequestMailer < ApplicationMailer
  layout false

  def new_support_request_email
    @support_request = params[:support_request]
    @user = User.find_by(id: @support_request["user_id"])
    reply_to = @user&.email || @support_request["email"]
    subject = @user ? "Support: #{reply_to}" : "Support (not signed in): #{reply_to}"
    mail(to: DefaultSetting::SUPPORT_EMAIL,
         subject: subject,
         content_type: "text/plain",
         reply_to: reply_to)
  end
end
