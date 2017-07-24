require 'rgl/adjacency'
require 'rgl/dijkstra'

# Tag class
class Tag < ApplicationRecord
  alias_attribute :disabled_lectures, :lectures
  has_many :course_contents
  has_many :courses, through: :course_contents
  has_many :disabled_contents
  has_many :disabled_lectures, through: :disabled_contents, source: :lecture
  has_many :additional_contents
  has_many :additional_lectures, through: :additional_contents, source: :lecture
  has_many :lesson_contents
  has_many :lessons, through: :lesson_contents
  has_many :section_contents
  has_many :sections, through: :section_contents
  has_many :asset_tags
  has_many :learning_assets, through: :asset_tags
  has_many :relations, dependent: :destroy
  has_many :related_tags, through: :relations, dependent: :destroy
  validates :title, presence: true, uniqueness: true

  def self.to_weighted_graph
    tag_relations = all.map { |t| [t.id, t.related_tags.map(&:id)] }.to_h
    edge_weights = {}
    graph = RGL::AdjacencyGraph.new
    ids.each { |t| graph.add_vertex(t) }
    tag_relations.each do |id, related|
      related.each do |neighbour|
        edge = [id, neighbour]
        graph.add_edges(edge)
        edge_weights.store(edge, 1)
      end
    end
    { graph: graph, weight_map: edge_weights }
  end

  def self.shortest_distance(tag1, tag2)
    g = to_weighted_graph
    graph = g[:graph]
    weight_map = g[:weight_map]
    path = graph.dijkstra_shortest_path(weight_map, tag1.id, tag2.id)
    return path.length - 1 unless path.nil?
  end

  def self.shortest_distances(tag)
    g = to_weighted_graph
    graph = g[:graph]
    weight_map = g[:weight_map]
    paths = graph.dijkstra_shortest_paths(weight_map, tag.id)
    paths.transform_values! { |v| v.nil? ? nil : v.length - 1 }
    paths.transform_keys! { |k| Tag.find(k) }
  end

  def tags_with_given_distance(distance)
    distance_list = self.class.shortest_distances(self)
    distance_list.select { |_k, v| v == distance }.keys
  end

  def neighbours
    Tag.where(id: Relation.select(:related_tag_id).where(tag_id: id))
       .or(Tag.where(id: Relation.select(:tag_id).where(related_tag_id: id)))
  end
end
