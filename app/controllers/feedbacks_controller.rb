class FeedbacksController < ApplicationController
  authorize_resource except: [:new, :create]
  before_action :require_turbo_frame, only: [:new]

  def new
    render partial: "feedbacks/form/form", locals: { feedback: Feedback.new }
  end

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.user_id = current_user.id

    if @feedback.save
      FeedbackMailer.with(feedback: @feedback).new_user_feedback_email.deliver_later
      respond_with_flash_success(I18n.t("feedback.success"))
    else
      render partial: "feedbacks/form/form", locals: { feedback: @feedback },
             status: :unprocessable_content
    end
  end

  private

    def feedback_params
      params.expect(feedback: [:title, :feedback, :can_contact])
    end
end
