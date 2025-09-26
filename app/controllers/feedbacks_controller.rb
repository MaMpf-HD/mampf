class FeedbacksController < ApplicationController
  authorize_resource except: [:form, :create]

  def form
    render partial: "feedbacks/form/feedback_form"
  end

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.user_id = current_user.id

    if @feedback.save
      FeedbackMailer.with(feedback: @feedback).new_user_feedback_email.deliver_later

      flash.now[:success] = I18n.t("feedback.success")
      respond_to do |format|
        format.turbo_stream do
          render_flash
        end
      end
    else
      # TODO
      render partial: "feedbacks/form/feedback_form", status: :unprocessable_entity
    end
  end

  private

    def feedback_params
      params.expect(feedback: [:title, :feedback, :can_contact])
    end
end
