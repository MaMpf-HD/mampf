# Quizzes controller
class QuizzesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:take, :proceed]
  before_action :set_quiz, except: [:new]
  # cancancan gem does not work well with single table inheritance
  # therefore, check access rights manually for :take and :proceed
  before_action :check_accessibility, only: [:take, :proceed]
  before_action :init_values, only: [:take, :proceed]
  authorize_resource
  layout 'administration'

  def new
  end

  def edit
    @quiz.save_png!
  end

  def update
    root = quiz_params[:root].to_i
    level = quiz_params[:level].to_i
    quiz_graph = @quiz.quiz_graph
    quiz_graph.root = root
    @success = true if @quiz.update(quiz_graph: quiz_graph,
                                    level: level)
  end

  def destroy
    @quiz.update(level: nil,
                 quiz_graph: nil)
    redirect_to edit_medium_path(@quiz)
  end

  def take
    render layout: 'quiz'
  end

  def proceed
    @quiz_round.update
  end

  def preview
    @quiz.save_png!
    send_file @quiz.image_path, type: 'image/png', disposition: 'inline'
  end

  private

  def set_quiz
    @quiz = Quiz.find_by_id(params[:id])
    return if @quiz.present?
    redirect_to :root, alert: 'Ein Quiz mit der angeforderten id '\
                              'existiert nicht.'
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
    redirect_to :root, alert: 'Du hast keine Berechtigung, auf dieses Quiz ' \
                              'zuzugreifen.'
  end
end
