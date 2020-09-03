# Solution class
# plain old ruby class, no active record involved
class Solution
  attr_reader :content
  attr_accessor :explanation

  def initialize(content)
    @content = content
  end

  def self.load(text)
    YAML.load(text) if text.present?
  end

  def self.dump(solution)
    solution.to_yaml
  end

  def type
    @content.class.name
  end

  def nerd
    @content.nerd
  end

  def tex
    return '' unless @content.tex
    '$$' + @content.tex + '$$'
  end

  def tex_mc_answer
    return '' unless @content.tex
    '$' + @content.tex + '$'
  end

  def self.from_hash(solution_type, content)
    return unless solution_type.in?(['MampfExpression', 'MampfMatrix',
                                     'MampfTuple', 'MampfSet'])
    solution = Solution.new(solution_type.constantize.from_hash(content))
    solution.explanation = content[:explanation]
    solution
  end
end