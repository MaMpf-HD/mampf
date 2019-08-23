# MampfNumber class
# plain old ruby class, no active record involved
class MampfNumber
  attr_accessor :value, :tex

  def initialize(value, tex)
    @value = value
    @tex = tex
  end

  # def equals?(z)
  #   @complex == z.complex
  # end

  def self.trivial_instance
    MampfNumber.new('0', '0')
  end

  # def proper_complex?
  #   @real != 0 && imaginary != 0
  # end

  # def proper_real?
  #   @imaginary == 0
  # end

  # def proper_imaginary?
  #   @real == 0
  # end

  # def trivial?
  #   equals?(MampfNumber.trivial_instance)
  # end

  # def to_tex
  #   return '0' if @complex == 0
  #   if @real == 0
  #     x = ''
  #   else
  #     real_sign = if @real.numerator < 0
  #                   '-'
  #                 else
  #                   ''
  #                 end
  #     if @real.denominator == 1
  #       x = real_sign + @real.numerator.abs.to_s
  #     else
  #       x = real_sign + '\frac{' + @real.numerator.abs.to_s + '}{' +
  #             @real.denominator.to_s + '}'
  #     end
  #   end
  #   return x if @imaginary == 0
  #   imaginary_sign = if @imaginary.numerator < 0
  #                      '-'
  #                    else
  #                      ''
  #                    end
  #   if @imaginary.denominator == 1
  #     if !@imaginary.numerator.in?([1,-1])
  #       y = imaginary_sign + @imaginary.numerator.abs.to_s
  #     else
  #       y = imaginary_sign
  #     end
  #   else
  #     y = imaginary_sign + '\frac{' + @imaginary.numerator.abs.to_s +
  #           '}{' + @imaginary.denominator.to_s + '}'
  #   end
  #   return x + '+' + y + 'i' if x.present? && imaginary_sign == ''
  #   return x +  y + 'i' if x.present?
  #   y + 'i'
  # end

  def self.from_hash(content)
    MampfNumber.new(content['0'], content['tex'])
  end

end