# MampfExpression class
# plain old ruby class, no active record involved
class MampfExpression
  attr_accessor :value, :tex

  def initialize(value, tex)
    @value = value
    @tex = tex
  end

  def self.trivial_instance
    MampfExpression.new('0', '0')
  end

  def self.from_hash(content)
    MampfExpression.new(content['0'], content['tex'])
  end
end