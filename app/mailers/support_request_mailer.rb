# Mails a message from the support button to the support address; the answer
# goes to whoever wrote it.
class SupportRequestMailer < ApplicationMailer
  layout false

  def new_support_request_email
    @request = params[:support_request]
    @user = User.find_by(id: @request["user_id"])
    reply_to = @user&.email || @request["email"]
    mail(to: DefaultSetting::SUPPORT_EMAIL,
         subject: "Support: #{reply_to}",
         content_type: "text/plain",
         reply_to: reply_to)
  end
end
