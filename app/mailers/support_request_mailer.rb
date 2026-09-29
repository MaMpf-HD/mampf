# Mails a message from the support button to the address people write to
# (PROJECT_EMAIL); the answer goes to whoever wrote it. The sender comes with
# the message, since the account may be gone by the time the job runs.
class SupportRequestMailer < ApplicationMailer
  layout false

  def new_support_request_email
    @support_request = params[:support_request]
    email = @support_request["user_email"]
    mail(to: DefaultSetting::PROJECT_EMAIL,
         subject: "Support: #{email}",
         content_type: "text/plain",
         reply_to: email)
  end
end
