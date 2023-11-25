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
    Quiz.where(id: quiz_ids, sort: "Quiz").pluck(:id)
  end

  def duplicate
    copy = dup
    copy.video_data = nil
    copy.manuscript_data = nil
    copy.screenshot_data = nil
    copy.editors = editors
    copy.parent_id = id
    copy.save
    copy.update(description: copy.description +
                               I18n.t("admin.question.copy_marker") +
                               copy.id.to_s)
    answer_map = {}
    answers.each { |a| answer_map[a.id] = a.duplicate(copy).id }
    [copy, answer_map]
  end

  def self.create_prefilled(label, teachable, editors)
    solution = Solution.new(MampfExpression.trivial_instance)
    question = Question.new(sort: "Question",
                            description: label,
                            teachable:,
                            editors:,
                            text: I18n.t("admin.question.initial_text"),
                            level: 1,
                            independent: false,
                            question_sort: "mc",
                            solution:)
    return question if question.invalid?

    Answer.create(question:,
                  text: "0",
                  value: true)
    question
  end

  def self. selection
    Question.all.map { |r| [r.label, r.id] }
  end

  def delete_vertices
    quiz_ids.each do |q|
      quiz = Quiz.find(q)
      vertices = quiz.quiz_graph.find_vertices(self)
      vertices.each do |v|
        quiz.update(quiz_graph: quiz.quiz_graph.destroy_vertex(v),
                    released: "locked")
      end
    end
    true
  end

  def multiple_choice?
    question_sort == "mc"
  end

  def free_answer?
    question_sort == "free"
  end

  def parametrized?
    parameters.present?
  end

  # filter variables
  def parsed_text_with_params
    text&.gsub(/\\para{(\w+),(.*?)}/, '{\color{blue}{\1}}')
  end

  def text_with_sample_params(parameters)
    return text unless parameters.present?

    result = text
    parameters.keys.each do |p|
      result.gsub!(/\\para{#{Regexp.escape(p)},(.*?)}/, parameters[p].to_s)
    end
    result
  end

  def parameters
    Question.parameters_from_text(text)
  end

  def sample_parameters
    parameters.each_with_object({}) do |(k, v), h|
      h[k] = v.to_a.sample
    end
  end

  def self.parameters_from_text(text)
    text.scan(/\\para{(\w+),(.*?)}/)
        .map { |v| [v[0], v[1].to_a_or_range] }
        .to_h
  end

  private

    def prelim_answer_table
      table = []
      size = answer_ids.count
      (0..(2**size) - 1).each do |i|
        hash = {}
        i.to_bool_a(size).each_with_index.map { |x, j| hash[answer_ids[j]] = x }
        table.push(hash)
      end
      table
    end
end
