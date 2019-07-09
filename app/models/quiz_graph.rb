# QuizGraph class
# represents the quizzes' internal logic as is stored in active record
class QuizGraph
  include ActiveModel::Model
  attr_accessor :vertices, :edges, :root, :default_table, :hide_solution

  def self.load(text)
    YAML.load(text) if text.present?
  end

  def self.dump(quiz_graph)
    quiz_graph.to_yaml
  end

  def update_vertex(vertex_id, default_id, branching, hide)
    remove_edges_from!(vertex_id)
    if @vertices[vertex_id][:type] == 'Remark'
      set_new_default_for_remark!(vertex_id, default_id)
    else
      new_edges = create_new_edges!(branching)
      set_new_default_for_question!(vertex_id, new_edges)
      update_hide_solutions!(hide, branching)
    end
    self
  end

  def create_vertex(quizzable)
    return self if quizzable.blank?
    return self if quizzable.invalid?
    id = new_vertex_id
    @vertices[id] = { type: quizzable.class.to_s, id: quizzable.id }
    @default_table[id] = 0
    @edges[[id, 0]] = quizzable.answer_table
    self
  end

  def destroy_vertex(id)
    @vertices.delete(id)
    bend_edges_deletion!(id)
    @default_table.delete(id)
    @default_table.transform_values! { |v| v == id ? 0 : v }
    @hide_solution = @hide_solution.select { |h| h[0] != id && h[1] != id }
    self
  end

  # replace_reference! replaces all references to old_quizzable within
  # the quiz_graph by references to new_quizzable. It proceeds only if
  # both quizzables are of the same class. If the quizzables are questions,
  # a mapping between the answer ids has to be supplied.
  # This method is supposed to be USED ONLY for replacing quizzables
  # by COPIES.

  def replace_reference!(old_quizzable, new_quizzable, answer_map = {})
    return self unless old_quizzable.class == new_quizzable.class
    affected_vertices = referencing_vertices(old_quizzable)
    affected_vertices.each { |v| @vertices[v][:id] = new_quizzable.id }
    return self unless new_quizzable.class.to_s == 'Question'
    affected_vertices.each do |v|
      bend_edges_rereferencing!(edges_from(v), answer_map)
      bend_hide_solution_rereferencing!(v, answer_map)
    end
    self
  end

  def reset_vertex_answers_change(id)
    edges_from(id).each { |e| @edges.delete(e) }
    @edges[[id, 0]] = quizzable(id).answer_table
    @default_table[id] = 0
    @hide_solution.reject! { |h| h[0] == id }
    self
  end

  def find_errors
    return [I18n.t('admin.quiz.no_vertices')] unless @vertices.present?
    branch_undef = @default_table.values.include?(0)
    no_end = @edges.select { |e| e[1] == -1 }.blank?
    no_root = @root.blank? || @root.zero?
    messages = []
    messages.push(I18n.t('admin.quiz.undefined_targets')) if branch_undef
    messages.push(I18n.t('admin.quiz.no_end')) if no_end
    messages.push(I18n.t('admin.quiz.no_start')) if no_root
    messages
  end

  def quizzable(id)
    return unless id.in?(@vertices.keys)
    @vertices[id][:type].constantize.find_by_id(@vertices[id][:id])
  end

  def find_vertices(quizzable)
    @vertices.select do |_k, v|
      v == { type: quizzable.class.to_s, id: quizzable.id }
    end
             .keys
  end

  def edges_from(id)
    @edges.keys.select { |k| k[0] == id }
  end

  def fallback_neighbours(id)
    list = neighbours(id)
    list.delete(0) if @default_table[id] != 0
    list
  end

  def fallback_neighbours_with_status(id)
    fallback_neighbours(id).map { |n| [n, n == @default_table[id]] }
  end

  def remove_hide_solution!(id)
    @hide_solution = @hide_solution.reject { |s| s[0] == id }
  end

  def set_new_default_for_remark!(vertex_id, default_id)
    @default_table[vertex_id] = default_id
    @edges[[vertex_id, default_id]] = []
  end

  def remove_edges_from!(vertex_id)
    edges_from(vertex_id).each { |e| @edges.delete(e) }
    remove_hide_solution!(vertex_id)
  end

  def create_new_edges!(branching)
    new_hash = Hash.new { |h, k| h[k] = [] }
    news = branching.each_with_object(new_hash) { |(k, v), h| h[v] << k }
    @edges.merge!(news)
    news
  end

  def set_new_default_for_question!(vertex_id, new_edges)
    new_default_edge = new_edges.keys.detect do |k|
      quizzable(vertex_id).answer_scheme.in?(new_edges[k])
    end
    @default_table[vertex_id] = new_default_edge[1]
  end

  def update_hide_solutions!(hide, branching)
    @hide_solution.concat(hide.map { |h| branching[h] + [h] })
  end

  def bend_edges_deletion!(id)
    edges_from(id).each { |e| @edges.delete(e) }
    incoming(id).each do |i|
      @edges[[i, 0]] ||= []
      @edges[[i, 0]].concat @edges[[i, id]]
      @edges.delete([i, id])
    end
  end

  def bend_edges_rereferencing!(affected_edges, answer_map)
    affected_edges.each do |e|
      @edges[e].each { |hash| hash.transform_keys! { |k| answer_map[k] } }
    end
  end

  def bend_hide_solution_rereferencing!(vertex, answer_map)
    affected_hide_solution = @hide_solution.select { |h| h[0] == vertex }
    affected_hide_solution.each do |h|
      h[2].transform_keys! { |k| answer_map[k] }
    end
  end

  def edges_to(id)
    @edges.keys.select { |k| k[1] == id }
  end

  def incoming(id)
    edges_to(id).map { |e| e[0] }
  end

  def neighbours(id)
    edges_from(id).map { |e| e[1] }
  end

  def referencing_vertices(quizzable)
    @vertices.keys.select do |k|
      @vertices[k][:type] == quizzable.class.to_s &&
        @vertices[k][:id] == quizzable.id
    end
  end

  def new_vertex_id
    return 1 unless @vertices.present?
    @vertices.keys.max + 1
  end

  def edge_color_for_cytoscape(edge)
    @default_table[edge[0]] == edge[1] ? '#32cd32' : '#f00'
  end

  def linearize!
    edges = {}
    default_table = {}
    @vertices.keys.each do |i|
      j = i < @vertices.count ? i + 1 : -1
      default_table[i] = j
      if @vertices[i][:type] == 'Question'
        question = quizzable(i)
        edges[[i, j]] = [question.answer_scheme]
        edges[[i, 0]] = question.answer_table - [question.answer_scheme]
      else
        edges[[i, j]] = []
      end
    end
    @edges = edges
    @root = @vertices.keys.first
    @default_table = default_table
    self
  end

  def self.build_from_questions(question_ids)
    vertices = {}
    edges = {}
    default_table = {}
    size = question_ids.size
    question_ids.each_with_index do |q,i|
      j = i + 1
      k =   j < size ? j + 1 : -1
      question = Question.find_by_id(q)
      vertices[j] = { type: 'Question', id: q }
      edges[[j, k]] = [question.answer_scheme]
      edges[[j, 0]] = question.answer_table - [question.answer_scheme]
      default_table[j] = k
    end
    QuizGraph.new(vertices: vertices, edges: edges, root: 1,
                  default_table: default_table, hide_solution: [])
  end

  def to_cytoscape
    result = []
    result.push(data: { id: '-2',
                        label: I18n.t('admin.quiz.start'),
                        color: '#000',
                        background: '#f4a460'} )
    # add vertices
    vertices.keys.each do |v|
      result.push(data: cytoscape_vertex(v))
    end
    result.push(data: { id: '-1',
                        label: I18n.t('admin.quiz.end'),
                        color: '#000',
                        background: '#f4a460'} )
    # add edges
    if @root.in?(@vertices.keys)
      result.push(data: { id: "-2-#{@root}",
                          source: -2,
                          target: 1,
                          color: '#aaa'} )
    end
    edges.keys.each do |e|
      next if e.second == 0
      result.push(data: cytoscape_edge(e))
    end
    result
  end

  def linear?
    @edges.keys.select { |e| e.second != 0 }
          .reject { |e| e.in?(default_table.to_a)}.empty?
  end

  # returns the cytoscape hash describing the vertex
  def cytoscape_vertex(id)
    { id: id.to_s,
      label: quizzable(id).description,
      color: '#000',
      background: '#666' }
  end

  # returns the cytoscape hash describing the edge
  def cytoscape_edge(edge)
    { id: "#{edge.first}-#{edge.second}",
      source: edge.first,
      target: edge.second,
      color: edge_color_for_cytoscape(edge) }
  end

  def questions_count
    @vertices.values.select { |v| v[:type] == 'Question'}.count
  end
end