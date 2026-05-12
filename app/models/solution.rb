# Solution class
# plain old ruby class, no active record involved
class Solution
  attr_reader :content
  attr_accessor :explanation

  def initialize(content)
    @content = content
  end

  def self.load(text)
    return if text.blank?

    YAML.safe_load(text, permitted_classes: [Solution,
                                             MampfTuple,
                                             MampfExpression,
                                             MampfMatrix,
                                             MampfSet],
                         aliases: true)
  end

  def self.dump(solution)
    solution.to_yaml
  end

  def type
    @content.class.name
  end

  delegate :nerd, to: :@content

  def tex
    return "" unless @content.tex

    "$$#{@content.tex}$$"
  end

  def tex_mc_answer
    return "" unless @content.tex

    "$#{@content.tex}$"
  end

  def self.from_hash(solution_type, content)
    allowed_types = {
      "MampfExpression" => MampfExpression,
      "MampfMatrix" => MampfMatrix,
      "MampfTuple" => MampfTuple,
      "MampfSet" => MampfSet
    }

    return unless allowed_types.key?(solution_type)

    solution = Solution.new(allowed_types[solution_type].from_hash(content))
    solution.explanation = content[:explanation]
    solution
  end
end
