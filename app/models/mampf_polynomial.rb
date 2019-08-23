# MampfPolynomial class
# plain old ruby class, no active record involved
class MampfPolynomial
  include ActiveModel::Model

  attr_accessor :coefficients

  def equals?(other_polynomial)
    return false unless @degree == other_polynomial.degree
    @coefficients.each_with_index do |c, i|
      return false unless c.equals?(other_polynomial.coefficients[i])
    end
    true
  end

  def degree
    return -1 if @coefficients.all?(&:trivial?)
    @coefficients.each_with_index
                .reject { |c, i| c.trivial? }
                .map(&:second).max
  end

  def self.trivial_instance
    MampfPolynomial.new(coefficients: [ MampfNumber.new('0'),
                                        MampfNumber.new('1'),
                                        MampfNumber.new('0'),
                                        MampfNumber.new('0'),
                                        MampfNumber.new('0'),
                                        MampfNumber.new('0')])
  end

  def to_tex
    return '0' if degree == -1
    return @coefficients[0].to_tex if degree == 0
    result = ''
    (0..degree).each do |k|
      i = degree - k
      coefficient = @coefficients[i]
      next if coefficient.equals?(MampfNumber.trivial_instance)
      if i == degree
        term = if coefficient.proper_complex?
                 "(#{coefficient.to_tex})"
               elsif coefficient.proper_real? && coefficient.real == 1
                 ""
               elsif coefficient.proper_real? && coefficient.real == -1
                 "-"
               else
                 "#{coefficient.to_tex}"
               end
      elsif i == 0
        term = if coefficient.proper_complex?
                 "+(#{coefficient.to_tex})"
               elsif coefficient.proper_real? && coefficient.real > 0
                 "+#{coefficient.to_tex}"
               elsif coefficient.proper_imaginary? && coefficient.imaginary > 0
                 "+#{coefficient.to_tex}"
               else
                 "#{coefficient.to_tex}"
               end
      else
        term = if coefficient.proper_complex?
                 "+(#{coefficient.to_tex})"
               elsif coefficient.proper_real? && coefficient.real == 1
                 ""
               elsif coefficient.proper_real? && coefficient.real == -1
                 "-"
               elsif coefficient.proper_real? && coefficient.real > 0
                 "+#{coefficient.to_tex}"
               elsif coefficient.proper_imaginary? && coefficient.imaginary > 0
                 "+#{coefficient.to_tex}"
               else
                 "#{coefficient.to_tex}"
               end
      end
      result += if i == 0
                  term
                elsif i == 1
                  term + 'X'
                else
                  term + "X^#{i}"
                end
    end
    result
  end

  def self.from_hash(content)
    max_degree = content['degree'].to_i
    coefficients = []
    (0..max_degree).each do |i|
      coefficients.push(MampfNumber.new(content["#{i}"]))
    end
    (max_degree + 1..5).each do |i|
      coefficients.push(MampfNumber.trivial_instance)
    end
    MampfPolynomial.new(coefficients: coefficients)
  end
end