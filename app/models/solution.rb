# MampfNumber class
# plain old ruby class, no active record involved
class Solution

  include ActiveModel::Model

  attr_accessor :type, :content

  def self.load(text)
    YAML.safe_load(text, [Solution, MampfNumber]) if text.present?
  end

  def self.dump(solution)
    solution.to_yaml
  end
end