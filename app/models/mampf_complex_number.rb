# MampfComplexNumber class
# plain old ruby class, no active record involved
class MampfComplexNumber
  include ActiveModel::Validations
  attr_accessor :value, :complex, :real, :imaginary

  def initialize(value)
    @value = value
    @complex = @value.to_c
    @real = @complex.real.to_r
    @imaginary = complex.imaginary.to_r
  end

  def equals?(z)
    @complex == z.complex
  end

  def self.trivial_instance
    MampfComplexNumber.new('1+i')
  end

  def to_tex
    return '0' if @complex == 0
    if @real == 0
      x = ''
    else
      real_sign = if @real.numerator < 0
                    '-'
                  else
                    ''
                  end
      if @real.denominator == 1
        x = real_sign + @real.numerator.abs.to_s
      else
        x = real_sign + '\frac{' + @real.numerator.abs.to_s + '}{' +
              @real.denominator.to_s + '}'
      end
    end
    return x if @imaginary == 0
    imaginary_sign = if @imaginary.numerator < 0
                       '-'
                     else
                       ''
                     end
    if @imaginary.denominator == 1
      if !@imaginary.numerator.in?([1,-1])
        y = imaginary_sign + @imaginary.numerator.abs.to_s
      else
        y = imaginary_sign
      end
    else
      y = imaginary_sign + '\frac{' + @imaginary.numerator.abs.to_s +
            '}{' + @imaginary.denominator.to_s + '}'
    end
    return x + '+' + y + 'i' if x.present? && imaginary_sign == ''
    return x +  y + 'i' if x.present?
    y + 'i'
  end

end