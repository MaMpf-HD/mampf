# QuizGraph class
# represents the quizzes' internal logic as is stored in active record
class QuizGraph
  include ActiveModel::Model
  attr_accessor :vertices, :edges, :root, :default_table, :hide_solution

  def self.load(text)
    return if text.blank?

    YAML.safe_load(text,
                   permitted_classes: [QuizGraph, Symbol],
                   aliases: true)
  end

  def self.dump(quiz_graph)
    quiz_graph.to_yaml
  end

  def update_vertex(vertex_id, branching, hide)
    return if @vertices[vertex_id][:type] == "Remark"

    remove_edges_from!(vertex_id)
    update_edges_for_question!(vertex_id, branching)
    update_hide_solutions!(vertex_id, hide)
    self
  end

  def create_vertex(quizzable)
    return self if quizzable.blank?
    return self if quizzable.invalid?

    id = new_vertex_id
    @vertices[id] = { type: quizzable.class.to_s, id: quizzable.id }
    @default_table[id] = 0
    self
  end

  def destroy_vertex(id)
    @vertices.delete(id)
    remove_edges_involving!(id)
    @hide_solution.reject! { |h| h[0] == id }
    @root = nil if @root == id
    self
  end

  def update_default_target!(source, target)
    @default_table[source] = target
    @edges.delete([source, target])
  end

  def delete_edge!(source, target)
    @default_table[source] = 0 if @default_table[source] == target
    answers = @edges[[source, target]]
    return unless answers

    @edges.delete([source, target])
    affected_hide_solution = @hide_solution.select do |h|
      h.first == source && h.second.in?(answers)
    end
    @hide_solution -= affected_hide_solution
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
    return self unless new_quizzable.class.to_s == "Question"

    affected_vertices.each do |v|
      bend_edges_rereferencing!(edges_from(v), answer_map)
      bend_hide_solution_rereferencing!(v, answer_map)
    end
    self
  end

  def reset_vertex_answers_change(id)
    edges_from(id).each { |e| @edges.delete(e) }
    @hide_solution.reject! { |h| h[0] == id }
    self
  end

  def find_errors
    return [I18n.t("admin.quiz.no_vertices")] unless @vertices.present?

    branch_undef = @default_table.values.include?(0)
    no_end = default_table.values.exclude?(-1) && @edges.select do |e|
      e[1] == -1
    end.blank?
    no_root = @root.blank? || @root.zero?
    messages = []
    messages.push(I18n.t("admin.quiz.undefined_targets")) if branch_undef
    messages.push(I18n.t("admin.quiz.no_end")) if no_end
    messages.push(I18n.t("admin.quiz.no_start")) if no_root
    messages
  end

  def warnings
    I18n.t("admin.quiz.unreleased_vertices") if unreleased_vertices?
  end

  def quizzable(id)
    return unless id.in?(@vertices.keys)

    @vertices[id][:type].constantize.find_by_id(@vertices[id][:id])
  end

  def visible?(id)
    quizzable(id).visible?
  end

  def unreleased_vertices?
    !@vertices.keys.all? { |v| visible?(v) }
  end

  def find_vertices(quizzable)
    @vertices.select do |_k, v|
      v == { type: quizzable.class.to_s, id: quizzable.id }
    end
             .keys
  end

  def edges_from_plus_default(id)
    result = []
    result.push([id, @default_table[id]]) unless @default_table[id].zero?
    result + @edges.keys.select { |k| k[0] == id }
  end

  def edges_from(id)
    @edges.keys.select { |k| k[0] == id }
  end

  def fallback_neighbours(id)
    list = neighbours(id)
    list.push(0) if list.empty?
    list
  end

  def fallback_neighbours_with_status(id)
    fallback_neighbours(id).map { |n| [n, n == @default_table[id]] }
  end

  def remove_hide_solution!(id)
    @hide_solution.reject! { |s| s[0] == id }
  end

  def remove_edges_from!(vertex_id)
    edges_from(vertex_id).each { |e| @edges.delete(e) }
    remove_hide_solution!(vertex_id)
  end

  def update_edges_for_question!(vertex_id, branching)
    new_hash = Hash.new { |h, k| h[k] = [] }
    new_edges = branching.each_with_object(new_hash) { |(k, v), h| h[v] << k }
    default_edge = [vertex_id, @default_table[vertex_id]]
    @edges.merge!(new_hash.except(default_edge))
  end

  def update_hide_solutions!(vertex_id, hide)
    @hide_solution.concat(hide.map { |h| [vertex_id, h] })
  end

  def remove_edges_involving!(id)
    edges_from(id).each { |e| @edges.delete(e) }
    incoming(id).each do |i|
      @edges.delete([i, id])
    end
    @default_table.delete(id)
    @default_table.transform_values! { |v| v == id ? 0 : v }
  end

  def bend_edges_rereferencing!(affected_edges, answer_map)
    affected_edges.each do |e|
      @edges[e].each { |hash| hash.transform_keys! { |k| answer_map[k] } }
    end
  end

  def bend_hide_solution_rereferencing!(vertex, answer_map)
    affected_hide_solution = @hide_solution.select { |h| h[0] == vertex }
    affected_hide_solution.each do |h|
      h[1].transform_keys! { |k| answer_map[k] }
    end
  end

  def edges_to(id)
    @edges.keys.select { |k| k[1] == id }
  end

  def incoming(id)
    edges_to(id).map { |e| e[0] }
  end

  def neighbours(id)
    edges_from_plus_default(id).map { |e| e[1] }
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
    @default_table[edge[0]] == edge[1] ? "#32cd32" : "#f00"
  end

  def border_color_for_cytoscape(id)
    quizzable = quizzable(id)
    return "orange" unless quizzable.visible?
    return "chocolate" if quizzable.restricted?

    "#222"
  end

  def linearize!
    default_table = {}
    keys = @vertices.keys
    keys.each_with_index do |val, index|
      default_table[val] = index < @vertices.count - 1 ? keys[index + 1] : -1
    end
    @edges = {}
    @root = @vertices.keys.first
    @default_table = default_table
    self
  end

  def self.build_from_questions(question_ids)
    vertices = {}
    edges = {}
    default_table = {}
    size = question_ids.size
    question_ids.each_with_index do |q, i|
      j = i + 1
      k =   j < size ? j + 1 : -1
      question = Question.find_by_id(q)
      vertices[j] = { type: "Question", id: q }
      default_table[j] = k
    end
    QuizGraph.new(vertices: vertices, edges: edges, root: 1,
                  default_table: default_table, hide_solution: [])
  end

  def to_cytoscape
    result = []
    result.push(data: { id: "-2",
                        label: I18n.t("admin.quiz.start"),
                        color: "#000",
                        background: "yellowgreen",
                        borderwidth: "0",
                        bordercolor: "grey",
                        shape: "diamond" })
    # add vertices
    @vertices.keys.each do |v|
      result.push(data: cytoscape_vertex(v))
    end
    result.push(data: { id: "-1",
                        label: I18n.t("admin.quiz.end"),
                        color: "#000",
                        background: "yellowgreen",
                        borderwidth: "0",
                        bordercolor: "#f4a460",
                        shape: "diamond" })
    # add edges
    if @root.in?(@vertices.keys)
      result.push(data: { id: "-2-#{@root}",
                          source: -2,
                          target: @root,
                          color: "#aaa" })
    end
    @vertices.keys.each do |v|
      edges_from_plus_default(v).each do |e|
        result.push(data: cytoscape_edge(e))
      end
    end
    result
  end

  def linear?
    @edges.empty?
  end

  # returns the cytoscape hash describing the vertex
  def cytoscape_vertex(id)
    { id: id.to_s,
      label: quizzable(id).description,
      color: "#000",
      background: @vertices[id][:type] == "Question" ? "#e1f5fe" : "#f9fbe7",
      borderwidth: "2",
      bordercolor: border_color_for_cytoscape(id),
      shape: @vertices[id][:type] == "Question" ? "ellipse" : "rectangle",
      defaulttarget: @default_table[id] }
  end

  # returns the cytoscape hash describing the edge
  def cytoscape_edge(edge)
    { id: "#{edge.first}-#{edge.second}",
      source: edge.first,
      target: edge.second,
      color: edge_color_for_cytoscape(edge),
      defaultedge: default?(edge) }
  end

  def questions_count
    @vertices.values.select { |v| v[:type] == "Question" }.count
  end

  def default?(edge)
    return false unless @default_table[edge.first]

    @default_table[edge.first] == edge.second
  end
end
