# Solution class
# plain old ruby class, no active record involved
class Solution
  attr_reader :content

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

  def self.from_hash(solution_type, content)
    return unless solution_type.in?(['MampfExpression', 'MampfMatrix',
                                     'MampfTuple'])
    Solution.new(solution_type.constantize.from_hash(content))
  end
end