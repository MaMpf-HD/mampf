class FeedbackMailer < ApplicationMailer
  default from: DefaultSetting::FEEDBACK_EMAIL
  layout false

  # Mail to the MaMpf developers including the new feedback of a user.
  def new_user_feedback_email
    @feedback = params[:feedback]
    reply_to_mail = @feedback.can_contact ? @feedback.user.email : ""
    subject = "Feedback: #{@feedback.title}"
    mail(to: DefaultSetting::FEEDBACK_EMAIL,
         subject: subject,
         content_type: "text/plain",
         reply_to: reply_to_mail)
  end
end
