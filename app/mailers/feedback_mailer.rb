# Mails a `Feedback` to FEEDBACK_EMAIL. The answer goes to its author.
class FeedbackMailer < ApplicationMailer
  layout false

  def new_feedback_email
    @feedback = params[:feedback]
    email = @feedback["user_email"]
    mail(to: ENV.fetch("FEEDBACK_EMAIL"),
         subject: "Feedback: #{email}",
         content_type: "text/plain",
         reply_to: email)
  end
end
