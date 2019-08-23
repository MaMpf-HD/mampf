# MampfNumber class
# plain old ruby class, no active record involved
class MampfNumber
  attr_accessor :value, :tex

  def initialize(value, tex)
    @value = value
    @tex = tex
  end

  def self.trivial_instance
    MampfNumber.new('0', '0')
  end

  def self.from_hash(content)
    MampfNumber.new(content['0'], content['tex'])
  end

end