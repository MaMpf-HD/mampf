class Remark < ApplicationRecord
  acts_as_tree
  has_one :medium, as: :quizzable
  validates_presence_of :medium
  validates :label, presence: true
  validates :label, uniqueness: true
  has_one_attached :image
  before_destroy :delete_vertices
  paginates_per 15

  def answer_table
    []
  end

  def quiz_ids
    Quiz.all.select { |q| id.in?(q.remark_ids) }.map(&:id)
  end

  def self.create_prefilled(label)
    Remark.create(label: label, text: 'Dummytext')
  end

  def duplicate
    copy = Remark.create(text: text,
                         label: SecureRandom.uuid,
                         parent: self)
    copy.update(label: label + '-KOPIE-' + copy.id.to_s)
    copy
  end

  def self. selection
    Remark.all.map { |r| [r.label, r.id] }
  end

  private

  def delete_vertices
    quiz_ids.each do |q|
      quiz = Quiz.find(q)
      vertices = quiz.vertices
                     .select { |_k, v| v == { type: 'Remark', id: id } }.keys
      vertices.each do |v|
        quiz.update(quiz_graph: quiz.quiz_graph.destroy_vertex(v))
      end
    end
  end
end
