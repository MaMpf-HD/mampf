class QuestionSampler

  def initialize(questions, tags, count)
    @questions = questions
    @tags = tags
    @count = count
  end

  def sample!
    # we use the following algorithm for one-pass weighted sampling:
    # http://utopia.duth.gr/~pefraimi/research/data/2007EncOfAlg.pdf
    # see also https://gist.github.com/O-I/3e0654509dd8057b539a
    sample = weighted_question_ids.max_by(@count) do |_, weight|
      rand**(1.0 / weight)
    end
    sample.map(&:first)
  end

  private

  def weighted_question_ids
    tag_ids = @tags.pluck(:id)
    weighted_questions = @questions.includes(:tags).map do |q|
      [q.id, (q.tag_ids & tag_ids).count]
    end
    weighted_questions.to_h.reject { |_k, v| v == 0 }
  end
end