class FeedbacksController < ApplicationController
  authorize_resource except: [:new, :create]

  def new
    render partial: "feedbacks/form/form", locals: { feedback: Feedback.new }
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
      render partial: "feedbacks/form/form",
             locals: { feedback: @feedback },
             status: :unprocessable_entity
    end
  end

  private

    def feedback_params
      params.expect(feedback: [:title, :feedback, :can_contact])
    end
end
