# Questions Controller
class QuestionsController < ApplicationController
  before_action :set_question, except: :reassign
  before_action :set_quizzes, only: [:reassign]
  before_action :check_solution_errors, only: [:update]
  authorize_resource except: :reassign
  layout "administration"

  def current_ability
    @current_ability ||= QuestionAbility.new(current_user)
  end

  def edit
    I18n.locale = @question.locale_with_inheritance
  end

  def update
    return if @errors

    ActiveRecord::Base.transaction do
      update_params = question_params.except(:solution_error)
      @success = true if @question.update(update_params)
      if question_params[:question_sort] == "free"
        answer = @question.answers.first
        @question.answers.where.not(id: answer.id).destroy_all
      end
      if question_params[:solution]
        answer = @question.answers.first
        @question.answers.where.not(id: answer.id).destroy_all
        answer.update(text: question_params[:solution].tex_mc_answer,
                      value: true,
                      explanation: question_params[:solution].explanation)
      end
      @no_solution_update = question_params[:solution].nil?
      @errors = @question.errors
    end
  end

  def reassign
    question_old = Question.find_by(id: params[:id])
    authorize! :reassign, question_old
    I18n.locale = question_old.locale_with_inheritance
    @question, answer_map = question_old.duplicate
    @question.editors = [current_user]
    @quizzes.each do |q|
      Quiz.find_by(id: q).replace_reference!(question_old, @question, answer_map)
    end
    I18n.locale = @question.locale_with_inheritance
    if question_params[:type] == "edit"
      redirect_to edit_question_path(@question)
      return
    end
    @quizzable = @question
    @mode = "reassigned"
    render "media/fill_quizzable_area"
  end

  def set_solution_type
    content = case params[:type]
              when "MampfExpression"
                MampfExpression.trivial_instance
              when "MampfMatrix"
                MampfMatrix.trivial_instance
              when "MampfTuple"
                MampfTuple.trivial_instance
              when "MampfSet"
                MampfSet.trivial_instance
    end
    @solution = Solution.new(content)
  end

  def cancel_question_basics
  end

  def cancel_solution_edit
  end

  def render_question_parameters
    @parameters = Question.parameters_from_text(params[:text])
  end

  private

    def set_question
      @question = Question.find_by(id: params[:id])
      return if @question.present?

      redirect_to :root, alert: I18n.t("controllers.no_question")
    end

    def set_quizzes
      quizzes = params[:question].select do |k, v|
        v == "1" && k.start_with?("quiz-")
      end
      @quizzes = quizzes.keys.map { |k| k.remove("quiz-").to_i }
    end

    def check_solution_errors
      return if params[:question][:solution_error].blank?

      @errors = ActiveModel::Errors.new(@question)
      @errors.add(:base, params[:question][:solution_error])
    end

    def question_params
      result = params
               .expect(question: [:label, :text, :type, :hint, :level,
                                  :question_sort, :independent, :vertex_id,
                                  :solution_type,
                                  :solution_error,
                                  { solution_content:
                                  [
                                    :row_count, :column_count, :tex, :nerd, :explanation,
                                    { dynamic: {} }
                                  ] }])
      if result[:solution_type] && result[:solution_content]
        result[:solution] = Solution.from_hash(result[:solution_type],
                                               result[:solution_content])
      end
      result.except(:solution_type, :solution_content)
    end
end
