# AnswersController
class AnswersController < ApplicationController
  before_action :set_answer, only: [:show, :edit, :update, :destroy]

  def new
    @answer = Answer.new(value: true)
  end

  def create
    @answer = Answer.new(answer_params)
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
    redirect_to root_path, alert: 'Eine Antwort mit der angeforderten id' \
                                  'existiert nicht.'
  end

  def answer_params
    params.require(:answer).permit(:text, :value, :explanation, :question_id)
  end
end
