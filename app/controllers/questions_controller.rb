# Questions Controller
class QuestionsController < ApplicationController
  before_action :set_question, except: [:reassign]
  before_action :set_quizzes, only: [:reassign]
  authorize_resource
  layout 'administration'

  def edit
    I18n.locale = @question.locale_with_inheritance
  end

  def update
    @success = true if @question.update(question_params)
    @no_solution_update = question_params[:solution].nil?
  end

  def reassign
    question_old = Question.find_by_id(params[:id])
    I18n.locale = question_old.locale_with_inheritance
    @question, answer_map = question_old.duplicate
    @question.editors = [current_user]
    @quizzes.each do |q|
      Quiz.find_by_id(q).replace_reference!(question_old, @question, answer_map)
    end
    I18n.locale = @question.locale_with_inheritance
    if question_params[:type] == 'edit'
      redirect_to edit_question_path(@question)
      return
    end
    @quizzable = @question
    @mode = 'reassigned'
    render 'events/fill_quizzable_area'
  end

  private

  def set_question
    @question = Question.find_by_id(params[:id])
    return if @question.present?
    redirect_to :root, alert: I18n.t('controllers.no_question')
  end

  def set_quizzes
    @quizzes = params[:question].select { |k, v| v == '1' && k.start_with?('quiz-') }
                                .keys.map { |k| k.remove('quiz-').to_i }
  end

  def question_params
    result = params.require(:question)
                   .permit(:label, :text, :type, :hint, :level,
                           :question_sort, :independent, :vertex_id,
                           :solution_type, :solution_content)
    if result[:solution_type].in?(['MampfNumber'])
      number = MampfNumber.new(result[:solution_content])
      result[:solution] = Solution.new(number)
    end
    result.except(:solution_type, :solution_content)
  end
end
