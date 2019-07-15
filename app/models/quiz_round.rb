# QuizRound class
# service model for quizzes_controller
class QuizRound
  include ActiveModel::Validations
  attr_reader :quiz, :counter, :progress, :crosses, :vertex, :is_question,
              :answer_scheme, :progress_old, :counter_old, :round_id_old,
              :input, :correct, :hide_solution, :vertex_old, :question_id,
              :answer_shuffle, :answer_shuffle_old

  def initialize(params)
    pp '**************************'
    pp params
    @quiz = Quiz.find(params[:id])
    @crosses = params[:quiz].present? ? params[:quiz][:crosses] || [] : []
    progress_counter(params)
    @vertex = @quiz.vertices[@progress]
    @vertex_old = @vertex
    question_details(params) if @vertex.present? && @vertex[:type] == 'Question'
    @answer_scheme ||= {}
    @answer_shuffle ||= []
    @answer_shuffle_old = []
  end

  def update
    @input = @quiz.crosses_to_input(@progress, @crosses)
    @correct = (@input == @answer_scheme)
    @progress = @quiz.next_vertex(@progress, @input)
    @counter += 1
    @hide_solution = @quiz.quiz_graph.hide_solution
                          .include?([@progress_old, @input])
    @vertex = @quiz.vertices[@progress]
    @answer_shuffle_old = @answer_shuffle
    update_answer_shuffle if @vertex && @vertex[:type] == 'Question'
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
    return I18n.t('admin.quiz.correct_result') if @correct
    I18n.t('admin.quiz.incorrect_result')
  end

  def answers
    return [] unless @answer_shuffle
    @answer_shuffle.map { |a| Answer.find_by_id(a) }
  end

  def answers_old
    return [] unless @answer_shuffle_old
    @answer_shuffle_old.map { |a| Answer.find_by_id(a) }
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

  def question_details(params)
    @is_question = true
    @question_id = @vertex[:id]
    @answer_scheme = Question.find(@question_id).answer_scheme
    if params[:quiz].present? && params[:quiz][:answer_shuffle].present?
      @answer_shuffle = JSON.parse(params[:quiz][:answer_shuffle]).map(&:to_i)
    else
      @answer_shuffle = Question.find(@question_id).answers.map(&:id).shuffle
    end
    pp @answer_shuffle
  end

  def update_answer_shuffle
    @answer_shuffle = Question.find_by_id(@vertex[:id])&.answers&.map(&:id)
                             &.shuffle
  end
end
