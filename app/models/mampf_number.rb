# MampfNumber class
# plain old ruby class, no active record involved
class MampfNumber
  include ActiveModel::Validations
  validate :parsable?
  validate :no_dependencies?

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def equals?(other_number)
    calculator = Dentaku::Calculator.new
    calculator.evaluate(@value) == calculator.evaluate(other_number.value)
  end

  def no_dependencies?
    calculator = Dentaku::Calculator.new
    dependencies = calculator.dependencies(@value)
    return true if dependencies.blank?
    errors.add(:base, I18n.t('math.expression_has_dependencies',
                             dependencies: dependencies.join(', ')))
    false
    rescue RuntimeError => e
      errors.add(:base, I18n.t('math.expression_problem',
                                  problem: "#{e.message.downcase}"))
    rescue Exception
      errors.add(:base, I18n.t('math.syntax_error'))
  end

  def parsable?
    calculator = Dentaku::Calculator.new
    return true if !calculator.evaluate(@value).nil?
    errors.add(:base, I18n.t('math.not_parsable'))
    false
  end

  def self.trivial_instance
    self.new('')
  end

  def self.valid_trivial_instance
    self.new('1')
  end

  def to_tex
    ''
  end
end