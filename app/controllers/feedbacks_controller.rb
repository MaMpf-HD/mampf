class FeedbacksController < ApplicationController
  authorize_resource except: [:create]

  def create
    feedback = Feedback.new(feedback_params)
    feedback.user_id = current_user.id
    @feedback_success = feedback.save

    if @feedback_success
      FeedbackMailer.with(feedback: feedback).new_user_feedback_email.deliver_later
    end

    respond_to(&:js)
  end

  private

    def feedback_params
      params.require(:feedback).permit(:title, :feedback, :can_contact)
    end
end
