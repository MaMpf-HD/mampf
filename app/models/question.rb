class Question < Medium
  has_many :answers, dependent: :delete_all
  before_destroy :delete_vertices

  def label
    description
  end

  def answer_scheme
    scheme = {}
    answers.each do |a|
      scheme[a.id] = a.value
    end
    scheme
  end

  def answer_table
    table = prelim_answer_table
    correct = table.index(answer_scheme)
    table[0], table[correct] = table[correct], table[0]
    table
  end

  def quiz_ids
    Quiz.all.select { |q| id.in?(q.question_ids) }.map(&:id)
  end

  def proper_quiz_ids
    Quiz.where(id: quiz_ids, sort: 'Quiz').pluck(:id)
  end

  def duplicate
    copy = self.dup
    copy.video_data = nil
    copy.manuscript_data = nil
    copy.screenshot_data = nil
    copy.editors = editors
    copy.parent_id = id
    copy.save
    copy.update(description: copy.description + '-KOPIE-' + copy.id.to_s)
    answer_map = {}
    answers.each { |a| answer_map[a.id] = a.duplicate(copy).id }
    [copy, answer_map]
  end

  def self.create_prefilled(label, teachable, editors)
    question = Question.new(sort: 'Question', description: label,
                            teachable: teachable, editors: editors,
                            text: 'Dummytext', level: 1, independent: false)
    return question if question.invalid?
    Answer.create(question: question, text: 'Dummyantwort', value: true)
    question
  end

  def self. selection
    Question.all.map { |r| [r.label, r.id] }
  end

  private

  def delete_vertices
    quiz_ids.each do |q|
      quiz = Quiz.find(q)
      vertices = quiz.quiz_graph.find_vertices(self)
      vertices.each do |v|
        quiz.update(quiz_graph: quiz.quiz_graph.destroy_vertex(v))
      end
    end
    true
  end

  def prelim_answer_table
    table = []
    size = answer_ids.count
    (0..2**size - 1).each do |i|
      hash = {}
      i.to_bool_a(size).each_with_index.map { |x, j| hash[answer_ids[j]] = x }
      table.push(hash)
    end
    table
  end
end
