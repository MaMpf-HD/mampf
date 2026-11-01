# Mails a `Feedback` from the muffin next to the support button, see
# `SupportMail`.
class FeedbacksController < ApplicationController
  include SupportMail

  THROTTLE_WINDOW = 1.hour
  LIMIT = 6
  THROTTLE_KEY = "feedbacks".freeze

  # The muffin also shows on these pages; a redirect would lose the feedback.
  skip_before_action :enforce_password_change, :enforce_personal_data, only: :create

  def create
    feedback = Feedback.new(feedback_params)

    return render_form(feedback, :unprocessable_content) unless feedback.valid?

    if support_mail_limit_reached?(THROTTLE_KEY, limit: LIMIT, window: THROTTLE_WINDOW)
      return render_form(feedback, :too_many_requests,
                         throttled: throttled_message(THROTTLE_WINDOW))
    end

    mail = support_mail("Feedback", to: ENV.fetch("FEEDBACK_EMAIL"), text: feedback.body)
    unless deliver_support_mail(mail, THROTTLE_KEY)
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
      params.expect(feedback: [:body])
    end

    def render_form(feedback, status, throttled: nil, send_failed: false)
      render turbo_stream: turbo_stream.update(
        "feedback-body",
        partial: "feedbacks/form",
        locals: { feedback: feedback, throttled: throttled, send_failed: send_failed }
      ), status: status
    end
end
