# Quizzes controller
class QuizzesController < ApplicationController
  before_action :init_values, only: [:take, :proceed]
  before_action :set_quiz, only: [:show, :edit, :update, :destroy, :preview]
  authorize_resource
  layout 'administration'

  def new
  end

  def create
    label = params[:quiz][:label]
    quiz = Quiz.create_prefilled(label)
    if quiz
      redirect_to edit_quiz_path(quiz)
      return
    end
    flash[:error] = 'Fehler beim Anlegen des Quizzes!'
    redirect_to quizzes_path
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
    redirect_to quizzes_path, alert: 'Ein Quiz mit der angeforderten id '\
                                     'existiert nicht.'
  end

  def init_values
    @quiz_round = QuizRound.new(params)
  end

  def quiz_params
    params.require(:quiz).permit(:label, :root, :level, :id_js)
  end
end
