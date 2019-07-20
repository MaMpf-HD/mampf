# Quizzes controller
class QuizzesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:take, :proceed]
  before_action :set_quiz, except: [:new]
  # cancancan gem does not work well with single table inheritance
  # therefore, check access rights manually for :take and :proceed
  before_action :check_accessibility, only: [:take, :proceed]
  before_action :check_vertex_accessibility, only: [:take]
  before_action :check_errors, only: [:take]
  before_action :init_values, only: [:take, :proceed]
  authorize_resource
  layout 'administration'

  def new
  end

  def edit
    @graph_elements = @quiz.quiz_graph.to_cytoscape.to_json
    @linear = @quiz.quiz_graph.linear?
    I18n.locale = @quiz.locale_with_inheritance
  end

  def update
  end

  def destroy
    @quiz.update(level: nil,
                 quiz_graph: nil)
    redirect_to edit_medium_path(@quiz)
  end

  def take
    I18n.locale = @quiz.locale_with_inheritance
    render layout: 'quiz'
  end

  def proceed
    I18n.locale = @quiz.locale_with_inheritance
    @quiz_round.update
  end

  def linearize
    quiz_graph = @quiz.quiz_graph
    @quiz.update(quiz_graph: quiz_graph.linearize!)
    redirect_to edit_quiz_path(@quiz)
  end

  def set_root
    quiz_graph = @quiz.quiz_graph
    quiz_graph.root = params[:root].to_i
    @quiz.update(quiz_graph: quiz_graph)
    redirect_to edit_quiz_path(@quiz)
  end

  def set_level
    @quiz.update(level: params[:level].to_i)
    head :ok, content_type: "text/html"
  end

  def update_default_target
    quiz_graph = @quiz.quiz_graph
    source = params[:source].to_i
    target = params[:target].to_i
    quiz_graph.update_default_target!(source, target)
    @quiz.update(quiz_graph: quiz_graph)
  end

  def delete_edge
    quiz_graph = @quiz.quiz_graph
    source = params[:source].to_i
    target = params[:target].to_i
    quiz_graph.delete_edge!(source, target)
    @quiz.update(quiz_graph: quiz_graph)
  end

  private

  def set_quiz
    @quiz = Quiz.find_by_id(params[:id])
    return if @quiz.present?
    redirect_to :root, alert: I18n.t('controllers.no_quiz')
  end

  def init_values
    @quiz_round = QuizRound.new(params)
  end

  def quiz_params
    params.require(:quiz).permit(:label, :root, :level, :id_js)
  end

  def check_accessibility
    return if @quiz.sort == 'RandomQuiz'
    return if user_signed_in? && @quiz.visible_for_user?(current_user)
    return if !user_signed_in? && @quiz.published_with_inheritance? &&
                @quiz.free?
    redirect_to :root, alert: I18n.t('controllers.no_quiz_access')
  end

  def check_vertex_accessibility
    return if @quiz.sort == 'RandomQuiz'
    if user_signed_in?
      return if current_user.in?(@quiz.editors_with_inheritance)
      return if current_user.admin
      return if @quiz.quizzables_visible_for_user?(current_user)
    end
    return if !user_signed_in? && @quiz.quizzables_free?
    redirect_to :root, alert: I18n.t('controllers.no_quiz_vertex_access')
  end

  def check_errors
    return if @quiz.sort == 'RandomQuiz'
    return unless @quiz.quiz_graph.find_errors.any?
    redirect_to :root, alert: I18n.t('controllers.quiz_has_error')
  end
end
