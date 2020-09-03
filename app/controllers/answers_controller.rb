# AnswersController
class AnswersController < ApplicationController
  before_action :set_answer, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def new
    @answer = Answer.new(value: true)
    I18n.locale = Question.find_by_id(params[:question_id])
                         &.locale_with_inheritance
  end

  def create
    @answer = Answer.new(answer_params)
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

  private

  def set_answer
    @answer = Answer.find_by_id(params[:id])
    return if @answer.present?
    redirect_to root_path, alert: I18n.t('controllers.no_answers')
  end

  def answer_params
    params.require(:answer).permit(:text, :value, :explanation, :question_id)
  end
end
