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
    @errors = @question.errors
    pp @errors[:base].join(", ")
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

  def set_solution_type
    content = if params[:type] == 'MampfNumber'
                MampfNumber.trivial_instance
              elsif params[:type] == 'MampfComplexNumber'
                MampfComplexNumber.trivial_instance
              else
                MampfMatrix.trivial_instance
              end
    @solution = Solution.new(content)
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
                           :solution_type,
                           solution_content: {})
    if result[:solution_type] == 'MampfNumber'
      number = MampfNumber.new(result[:solution_content]['0'])
      result[:solution] = Solution.new(number)
    elsif result[:solution_type] == 'MampfComplexNumber'
      number = MampfComplexNumber.new(result[:solution_content]['0'])
      result[:solution] = Solution.new(number)
    elsif result[:solution_type] == 'MampfMatrix'
      row_count = result[:solution_content]['row_count'].to_i
      column_count = result[:solution_content]['column_count'].to_i
      domain = result[:solution_content]['domain']
      if domain.in?(['MampfNumber', 'MampfComplexNumber'])
        coefficients = []
        (1..row_count).each do |i|
          (1..column_count).each do |j|
            coefficients.push(domain.constantize
                                    .new(result[:solution_content]["#{i},#{j}"]))
          end
        end
        matrix = MampfMatrix.new(row_count: row_count,
                                 column_count: column_count,
                                 domain: domain,
                                 coefficients: coefficients)
        result[:solution] = Solution.new(matrix)
      end
    end
    result.except(:solution_type, :solution_content)
  end
end
