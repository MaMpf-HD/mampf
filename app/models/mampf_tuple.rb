# MampfTupel class
# plain old ruby class, no active record involved
class MampfTuple
  attr_reader :value, :tex

  def initialize(value, tex)
    @value = value
    @tex = tex
  end

  def self.trivial_instance
    self.new('0,1', '(0,1)')
  end

  def self.from_hash(content)
    MampfTuple.new(content['0'], content['tex'])
  end
end