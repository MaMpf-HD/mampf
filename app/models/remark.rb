class Remark < Medium
  before_destroy :delete_vertices

  def answer_table
    []
  end

  def label
    description
  end

  def quiz_ids
    Quiz.all.select { |q| id.in?(q.remark_ids) }.map(&:id)
  end

  def self.create_prefilled(label, teachable, editors)
    remark = Remark.new(sort: 'Remark', description: label,
                        teachable: teachable, editors: editors,
                        text: 'Dummytext')
    remark.save
    remark
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
