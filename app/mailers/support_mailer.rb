# Mails what somebody wrote into a form of the support button or the feedback
# muffin (see `FormMail`) to the team. The answer goes to whoever wrote it.
class SupportMailer < ApplicationMailer
  layout false

  def new_message_email
    @text = params[:text]
    @sender = params[:sender]
    email = @sender["user_email"]
    mail(to: params[:to],
         subject: "#{params[:kind]}: #{email}",
         content_type: "text/plain",
         reply_to: email,
         template_path: "support_requests/mails")
  end
end
