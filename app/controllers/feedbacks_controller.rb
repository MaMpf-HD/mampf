# Mails the answers of the temporary feedback survey (the muffin next to the
# support button) to the team, see `FormMail`. The mail names the author only
# if they agreed to be contacted.
class FeedbacksController < ApplicationController
  include FormMail

  THROTTLE_WINDOW = 1.hour
  LIMIT = 6
  THROTTLE_KEY = "feedbacks".freeze

  def create
    feedback = Feedback.new(feedback_params)

    return render_form(feedback, :unprocessable_content) unless feedback.valid?

    if form_mail_limit_reached?(THROTTLE_KEY, limit: LIMIT, window: THROTTLE_WINDOW)
      return render_form(feedback, :too_many_requests,
                         throttled: throttled_message(THROTTLE_WINDOW))
    end

    mail = FeedbackMailer.with(feedback: mail_details(feedback)).new_feedback_email
    unless deliver_form_mail(mail, THROTTLE_KEY)
      return render_form(feedback, :service_unavailable, send_failed: true)
    end

    render turbo_stream: turbo_stream.update(
      "feedback-body",
      partial: "feedbacks/sent",
      locals: { feedback: Feedback.new }
    )
  end

  private

    def feedback_params
      params.expect(feedback: [:body, :can_contact])
    end

    def mail_details(feedback)
      details = { "body" => feedback.body }
      return details unless feedback.can_contact

      details.merge("user_id" => current_user.id,
                    "user_name" => current_user.tutorial_name,
                    "user_email" => current_user.email)
    end

    def render_form(feedback, status, throttled: nil, send_failed: false)
      render turbo_stream: turbo_stream.update(
        "feedback-body",
        partial: "feedbacks/form",
        locals: { feedback: feedback, throttled: throttled, send_failed: send_failed }
      ), status: status
    end
end
