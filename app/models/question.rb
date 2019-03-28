class Question < ApplicationRecord
  acts_as_tree
  has_one :medium, as: :quizzable
  validates_presence_of :medium
  has_many :answers, dependent: :delete_all
  before_destroy :delete_vertices
  validates :label, presence: true
  validates :label, uniqueness: true
  paginates_per 15

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

  def duplicate
    medium_copy = medium.dup
    medium_copy.editors = medium.editors
    medium_copy.video_data = nil
    medium_copy.manuscript_data = nil
    medium_copy.screenshot_data = nil
    copy = Question.create(text: text,
                           label: SecureRandom.uuid,
                           parent: self,
                           medium: medium_copy)
    copy.update(label: label + '-KOPIE-' + copy.id.to_s)
    medium_copy.update(description: medium_copy.description + '-KOPIE-' +
                                    copy.id.to_s)
    answer_map = {}
    answers.each { |a| answer_map[a.id] = a.duplicate(copy).id }
    [copy, answer_map]
  end

  def self.create_prefilled(label, teachable, editors)
    medium = Medium.new(sort: 'KeksQuestion', description: label,
                        teachable: teachable, editors: editors)
    question = Question.new(label: label, text: 'Dummytext')
    medium.quizzable = question
    question.medium = medium
    question.save
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
