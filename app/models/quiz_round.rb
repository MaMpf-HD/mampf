# QuizRound class
# service model for quizzes_controller
class QuizRound
  include ActiveModel::Validations
  attr_reader :quiz, :counter, :progress, :crosses, :vertex, :is_question,
              :answer_scheme, :progress_old, :counter_old, :round_id_old,
              :input, :correct, :hide_solution, :vertex_old, :question_id,
              :answer_shuffle, :answer_shuffle_old, :solution_input, :result,
              :session_id, :study_participant, :is_remark, :remark_id,
              :input_text, :certificate

  def initialize(params)
    @quiz = Quiz.find(params[:id])
    @crosses = params[:quiz].present? ? params[:quiz][:crosses] || [] : []
    if params[:quiz].present?
      @solution_input = params[:quiz][:solution_input]
      @result = params[:quiz][:result]
      @input_text = params[:quiz][:input_text]
    end
    progress_counter(params)
    @vertex = @quiz.vertices[@progress]
    @vertex_old = @vertex
    question_details(params) if @vertex.present? && @vertex[:type] == 'Question'
    remark_details(params) if @vertex.present? && @vertex[:type] == 'Remark'
    @answer_scheme ||= {}
    @answer_shuffle ||= []
    @answer_shuffle_old = []
    @study_participant = params[:study_participant]
  end

  def update
    @input = @quiz.crosses_to_input(@progress, @crosses)
    @correct = (@input == @answer_scheme)
    create_question_probe if @is_question
    create_remark_probe if @is_remark && @study_participant
    @progress = @quiz.next_vertex(@progress, @input)
    create_certificate_final_probe if @progress == -1 && @quiz.sort == 'Quiz'
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
      @session_id = params[:quiz][:session_id]
    end
    @progress ||= @quiz.root
    @counter ||= 0
    @session_id ||= SecureRandom.uuid.first(13).remove('-')
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
  end

  def remark_details(params)
    @is_remark = true
    @remark_id = @vertex[:id]
  end

  def update_answer_shuffle
    @answer_shuffle = Question.find_by_id(@vertex[:id])&.answers&.map(&:id)
                             &.shuffle
  end

  def create_question_probe
    quiz_id = @quiz.id unless @quiz.sort == 'RandomQuiz'
    input = @solution_input || @input.to_s if @study_participant
    ProbeSaver.perform_async(quiz_id, @question_id, nil, @correct, @progress,
                             @session_id, @study_participant, input)
  end

  def create_remark_probe
    quiz_id = @quiz.id unless @quiz.sort == 'RandomQuiz'
    ProbeSaver.perform_async(quiz_id, nil, @remark_id, nil, @progress,
                             @session_id, @study_participant, @input_text)
  end

  def create_certificate_final_probe
    @certificate = QuizCertificate.create(quiz: @quiz)
    ProbeSaver.perform_async(@quiz.id, nil, nil, nil, -1, @session_id,
                             @study_participant, nil)
  end
end
