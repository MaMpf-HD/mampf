# QuizRound class
# service model for quizzes_controller
class QuizRound
  include ActiveModel::Validations
  attr_reader :quiz, :counter, :progress, :crosses, :vertex, :is_question,
              :answer_scheme, :progress_old, :counter_old, :round_id_old,
              :input, :correct, :hide_solution, :vertex_old

  def initialize(params)
    @quiz = Quiz.find(params[:id])
    @crosses = params[:quiz].present? ? params[:quiz][:crosses] || [] : []
    progress_counter(params)
    @vertex = @quiz.vertices[@progress]
    @vertex_old = @vertex
    question_details if @vertex.present? && @vertex[:type] == 'Question'
    @answer_scheme ||= {}
  end

  def update
    @input = @quiz.crosses_to_input(@progress, @crosses)
    @correct = (@input == @answer_scheme)
    @progress = @quiz.next_vertex(@progress, true, @input)
    @counter += 1
    @hide_solution = @quiz.quiz_graph.hide_solution
                          .include?([@progress_old, @progress, @input]) ||
                     @quiz.quiz_graph.hide_solution
                          .include?([@progress_old, 0, @input])
    @vertex = @quiz.vertices[@progress]
    self
  end

  def round_id
    'round' + @progress.to_s + '-' + @counter.to_s
  end

  def background
    return 'bg-grey-lighten-4' if @hide_solution
    return 'bg-correct' if @correct
    'bg-incorrect'
  end

  def badge
    'badge badge-' + (@correct ? 'success' : 'danger')
  end

  def statement
    (@correct ? 'richtig ' : 'falsch ') + 'beantwortet'
  end

  private

  def progress_counter(params)
    if params[:quiz].present?
      @counter = params[:quiz][:counter].to_i
      @progress = params[:quiz][:progress].to_i
    end
    @progress ||= @quiz.root
    @counter ||= 0
    @progress_old = @progress
    @counter_old = @counter
    @round_id_old = round_id
  end

  def question_details
    @is_question = true
    @answer_scheme = Question.find(@vertex[:id]).answer_scheme
  end
end
