# Mails a `Feedback` to FEEDBACK_EMAIL. With `can_contact`, the answer goes to
# its author; otherwise the mail names nobody.
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
