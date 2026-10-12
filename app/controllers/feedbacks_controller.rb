# Mails the answers of the temporary feedback survey (the muffin next to the
# support button) to the team. The mail names the author only if they agreed
# to be contacted. Answers are not stored, so the mail goes out right away: the
# thanks only come once it is sent, and otherwise the author keeps their text.
class FeedbacksController < ApplicationController
  THROTTLE_WINDOW = 1.hour
  LIMIT = 6

  def create
    feedback = Feedback.new(feedback_params)

    return render_form(feedback, :unprocessable_content) unless feedback.valid?

    if over_limit?
      return render_form(feedback, :too_many_requests,
                         throttled: throttled_message(THROTTLE_WINDOW))
    end

    return render_send_failure(feedback) unless send_mail(feedback)

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

    # `deliver_now!` raises on any failure, even where `raise_delivery_errors`
    # is off. Only the kind of error is logged, never the answer.
    def send_mail(feedback)
      FeedbackMailer.with(feedback: mail_details(feedback)).new_feedback_email.deliver_now!
      true
    rescue StandardError => e
      Rails.logger.error("Feedback could not be mailed: #{e.class}")
      false
    end

    def mail_details(feedback)
      details = { "body" => feedback.body }
      return details unless feedback.can_contact

      details.merge("user_id" => current_user.id,
                    "user_name" => current_user.tutorial_name,
                    "user_email" => current_user.email)
    end

    # Only answers that are mailed are counted. Without the cache the count is
    # nil, and the form stays open.
    def over_limit?
      count = Rails.cache.increment(throttle_key, 1, expires_in: THROTTLE_WINDOW)
      count.present? && count > LIMIT
    end

    def throttle_key
      "feedbacks:#{current_user.id}"
    end

    # An answer that could not be mailed does not use up the limit.
    def render_send_failure(feedback)
      Rails.cache.decrement(throttle_key, 1)
      render_form(feedback, :service_unavailable, send_failed: true)
    end

    def render_form(feedback, status, throttled: nil, send_failed: false)
      render turbo_stream: turbo_stream.update(
        "feedback-body",
        partial: "feedbacks/form",
        locals: { feedback: feedback, throttled: throttled, send_failed: send_failed }
      ), status: status
    end
end
