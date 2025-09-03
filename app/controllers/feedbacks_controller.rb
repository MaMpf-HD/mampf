class FeedbacksController < ApplicationController
  authorize_resource except: [:create]

  def create
    feedback = Feedback.new(feedback_params)
    feedback.user_id = current_user.id
    @feedback_success = feedback.save

    if @feedback_success
      FeedbackMailer.with(feedback: feedback).new_user_feedback_email.deliver_later
    end

    respond_to do |format|
      format.js { render template: "feedbacks/create/create" }
    end
  end

  private

    def feedback_params
      params.expect(feedback: [:title, :feedback, :can_contact])
    end
end
