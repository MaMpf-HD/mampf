# Mails a `Feedback` from the muffin next to the support button, see
# `FormMail`. Only with `can_contact` does the mail name its author.
class FeedbacksController < ApplicationController
  include FormMail

  THROTTLE_WINDOW = 1.hour
  LIMIT = 6
  THROTTLE_KEY = "feedbacks".freeze
  # Set once Mama Muffin on the dashboard should not ask anymore: after a sent
  # feedback, or when the user clicked her away.
  MAMA_COOKIE = "feedback_mama_hidden".freeze

  # The muffin also shows on these pages; a redirect would lose the feedback.
  skip_before_action :enforce_password_change, :enforce_personal_data, only: :create

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

    cookies[MAMA_COOKIE] = { value: "1", expires: 1.year, same_site: :lax }
    render turbo_stream: [
      turbo_stream.update("feedback-body", partial: "feedbacks/sent",
                                           locals: { feedback: Feedback.new }),
      turbo_stream.remove("mama-muffin")
    ]
  end

  private

    def feedback_params
      params.expect(feedback: [:body, :can_contact])
    end

    def mail_details(feedback)
      details = { "body" => feedback.body }
      return details unless feedback.can_contact

      details.merge(form_mail_sender)
    end

    def render_form(feedback, status, throttled: nil, send_failed: false)
      render turbo_stream: turbo_stream.update(
        "feedback-body",
        partial: "feedbacks/form",
        locals: { feedback: feedback, throttled: throttled, send_failed: send_failed }
      ), status: status
    end
end
