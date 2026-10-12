# Mails an answer of the temporary feedback survey to the feedback address
# (FEEDBACK_EMAIL). An anonymous answer names nobody; otherwise the sender
# comes with it and is the one a reply goes to.
class FeedbackMailer < ApplicationMailer
  layout false

  def new_feedback_email
    @feedback = params[:feedback]
    email = @feedback["user_email"]
    mail(to: ENV.fetch("FEEDBACK_EMAIL"),
         subject: email ? "Feedback: #{email}" : "Feedback (anonymous)",
         content_type: "text/plain",
         reply_to: email)
  end
end
