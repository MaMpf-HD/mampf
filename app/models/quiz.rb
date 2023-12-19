class Quiz < Medium
  def self.new_prefilled
    Quiz.new(level: 1,
             quiz_graph: QuizGraph.new(vertices: {}, edges: {}, root: 0,
                                       default_table: {}, hide_solution: []))
  end

  def self.create_prefilled(_label)
    Quiz.create(level: 1,
                quiz_graph: QuizGraph.new(vertices: {}, edges: {}, root: 0,
                                          default_table: {}, hide_solution: []))
  end

  def label
    description
  end

  def publish_vertices!(user, release_state)
    return unless vertices

    vertices.each_key do |v|
      quizzable = quizzable(v)
      next if quizzable.published?
      next unless quizzable.teachable.published?
      next unless user.in?(quizzable.editors_with_inheritance) || user.admin

      quizzable.update(released: release_state, released_at: Time.zone.now)
    end
  end

  def quizzables
    Medium.where(id: question_ids + remark_ids)
  end

  def quizzables_free?
    quizzables.where(released: "all").count == quizzables.count
  end

  def quizzables_visible_for_user?(user)
    quizzables.all? { |q| q.visible_for_user?(user) }
  end

  def next_vertex(progress, input = {})
    return default_table[progress] if vertices[progress][:type] == "Remark"

    target_vertex(progress, input)
  end

  def replace_reference!(old_quizzable, new_quizzable, answer_map = {})
    update(quiz_graph: quiz_graph.replace_reference!(old_quizzable,
                                                     new_quizzable, answer_map))
  end

  def vertices
    return if quiz_graph.nil?

    quiz_graph.vertices
  end

  def edges
    return if quiz_graph.nil?

    quiz_graph.edges
  end

  def root
    return if quiz_graph.nil?

    quiz_graph.root
  end

  def default_table
    return if quiz_graph.nil?

    quiz_graph.default_table
  end

  def question_ids
    return [] unless quiz_graph && quiz_graph.vertices.present?

    quiz_graph.vertices.select { |_k, v| v[:type] == "Question" }
              .values.pluck(:id).uniq
  end

  def remark_ids
    return [] unless quiz_graph && quiz_graph.vertices.present?

    quiz_graph.vertices.select { |_k, v| v[:type] == "Remark" }.values
              .pluck(:id).uniq
  end

  def crosses_to_input(vertex_id, crosses)
    vertex = vertices[vertex_id]
    input = {}
    if vertex[:type] == "Question"
      question = Question.find(vertex[:id])
      crosses = crosses.map(&:to_i)
      input = question.answers.to_h { |a| [a.id, crosses.include?(a.id)] }
    end
    input
  end

  delegate :quizzable, to: :quiz_graph

  def preselected_branch(vertex_id, crosses, fallback)
    successor = next_vertex(vertex_id, crosses)
    return successor unless successor == default_table[vertex_id] && fallback

    0
  end

  def preselected_hide_solution(vertex_id, crosses)
    [vertex_id, crosses].in?(quiz_graph.hide_solution)
  end

  def questions
    ids = quiz_graph&.vertices&.values&.select { |v| v[:type] == "Question" }
                    &.map { |v| v[:id] }
    Question.where(id: ids)
  end

  def questions_count
    return 0 unless quiz_graph

    quiz_graph.questions_count
  end

  def find_errors
    Rails.cache.fetch("#{cache_key_with_version}/find_errors") do
      quiz_graph&.find_errors
    end
  end

  private

    def target_vertex(progress, input)
      edges.select { |e, t| e[0] == progress && t.include?(input) }&.keys
           &.first&.second || default_table[progress]
    end
end
