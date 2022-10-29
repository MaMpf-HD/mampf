# frozen_string_literal: true

# QuestionSampler class
# This is a service PORO model that is used in the generation of quizzes
class QuestionSampler
  # questions is an ActiveRecordRelation (not an array) of questions
  # tags is ActiveRecordRelation (not an array) of tags
  # count is a positive integer
  def initialize(questions, tags, count)
    @questions = questions
    @tags = tags
    @count = count
  end

  # it returns an array of question ids that consists of ids of questions
  # from the given list, where the probability that a given question occurs
  # is proportional to the number of tags that the question has in common with
  # the given list of tags - in particular, questions that do not share
  # a tag with the given list of tags will not occur in the result
  # the length of the array will be the given count if the number of
  # given questions that have a tag in common with the given tags is >=
  # count; otherwise it will be that number
  # we use the following algorithm for one-pass weighted sampling:
  # http://utopia.duth.gr/~pefraimi/research/data/2007EncOfAlg.pdf
  # see also https://gist.github.com/O-I/3e0654509dd8057b539a
  def sample!
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
      weighted_questions.to_h.reject { |_k, v| v.zero? }
    end
end
