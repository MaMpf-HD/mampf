# Stores the answers of the temporary feedback survey (the muffin next to the
# support button) and mails them to the team. Answers are stored without their
# author; the mail names the author only if they agreed to be contacted.
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

    feedback.save!
    FeedbackMailer.with(feedback: mail_details(feedback)).new_feedback_email.deliver_later
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

    # Only answers that are stored are counted. Without the cache the count is
    # nil, and the form stays open.
    def over_limit?
      count = Rails.cache.increment("feedbacks:#{current_user.id}", 1,
                                    expires_in: THROTTLE_WINDOW)
      count.present? && count > LIMIT
    end

    def render_form(feedback, status, throttled: nil)
      render turbo_stream: turbo_stream.update(
        "feedback-body",
        partial: "feedbacks/form",
        locals: { feedback: feedback, throttled: throttled }
      ), status: status
    end
end
