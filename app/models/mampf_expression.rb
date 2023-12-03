# MampfExpression class
# plain old ruby class, no active record involved
class MampfExpression
  attr_reader :value, :tex, :nerd

  def initialize(value, tex, nerd)
    @value = value
    @tex = tex
    @nerd = nerd
  end

  def self.trivial_instance
    MampfExpression.new('0', '0', '0')
  end

  def self.from_hash(content)
    MampfExpression.new(content['0'], content['tex'], content['nerd'])
  end
end
