# MampfNumber class
# plain old ruby class, no active record involved
class MampfNumber

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def equals?(other_number)
    calculator = Dentaku::Calculator.new
    calculator.evaluate(@value) == calculator.evaluate(other_number.value)
  end
end