class FeedbacksController < ApplicationController
  authorize_resource except: [:create]

  def create
    feedback = Feedback.new(feedback_params)
    feedback.user_id = current_user.id
    successfully_saved = feedback.save
    flash.now[:status_msg] = if successfully_saved
      'Feedback successfully sent.'
    else
      'Something went wrong.'
    end
    @errors = feedback.errors
    # # redirect_to :root, alert: @errors.full_messages.join(', ')
    respond_to(&:js)
  end

  private

    def feedback_params
      params.require(:feedback).permit(:title, :feedback, :can_contact)
    end
end
