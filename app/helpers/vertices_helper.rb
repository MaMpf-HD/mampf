# Vertices Helper
module VerticesHelper
  def vertices_labels(quiz, vertex_id, undefined)
    special = [[undefined ? 'undefined' : 'default', 0], ['Ende', -1]]
    list = (quiz.vertices.keys - [vertex_id]).collect do |k|
      [k.to_s + ' ' + quiz.quizzable(k).label, k]
    end
    special.concat list
  end

  def crosses_id(crosses)
    crosses.keys.collect { |k| [k, crosses[k].to_s.first] }.flatten.join
  end
end