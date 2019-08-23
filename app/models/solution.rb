# Solution class
# plain old ruby class, no active record involved
class Solution

  attr_accessor :content
  attr_reader :value

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

  def valid_content?
    return true if content.valid?
    errors.add(:base, content.errors[:base].join(' '))
  end

  def self.from_hash(solution_type, content)
    return unless solution_type.in?(['MampfExpression'])
    Solution.new(solution_type.constantize.from_hash(content))
  end
end