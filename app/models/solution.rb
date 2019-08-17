# MampfNumber class
# plain old ruby class, no active record involved
class Solution

  attr_accessor :content
  attr_reader :value

  def initialize(content)
    @content = content
  end

  def self.load(text)
    YAML.safe_load(text, [Solution, MampfNumber]) if text.present?
  end

  def self.dump(solution)
    solution.to_yaml
  end

  def type
    @content.class.name
  end
end