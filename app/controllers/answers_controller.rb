# AnswersController
class AnswersController < ApplicationController
  before_action :set_answer, except: [:new, :create, :update_answer_box]
  authorize_resource except: [:new, :create]

  def current_ability
    @current_ability ||= AnswerAbility.new(current_user)
  end

  def new
    question = Question.find_by_id(params[:question_id])
    @answer = Answer.new(value: true, question: question)
    authorize! :new, @answer
    I18n.locale = question&.locale_with_inheritance
  end

  def create
    @answer = Answer.new(answer_params)
    authorize! :create, @answer
    I18n.locale = @answer.question&.locale_with_inheritance
    return unless @answer.save

    @success = true
  end

  def update
    @answer.update(answer_params)
  end

  def destroy
    @id = params[:id]
    return unless @answer.destroy

    @success = true
  end

  def update_answer_box
    @answer_id = params[:answer_id].to_i
    @value = params[:value] == "true"
  end

  private

    def set_answer
      @answer = Answer.find_by_id(params[:id])
      return if @answer.present?

      redirect_to root_path, alert: I18n.t("controllers.no_answer")
    end

    def answer_params
      params.require(:answer).permit(:text, :value, :explanation, :question_id)
    end
end
