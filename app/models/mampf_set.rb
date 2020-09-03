# MampfSet class
# plain old ruby class, no active record involved
class MampfSet
  attr_reader :value, :tex, :nerd

  def initialize(value, tex, nerd)
    @value = value
    @tex = tex
    @nerd = nerd
  end

  def self.trivial_instance
    self.new('0,1', '\{0,1\}', 'vector(0,1)')
  end

  def self.from_hash(content)
    MampfSet.new(content['0'], content['tex'], content['nerd'])
  end
end