# MampfMatrix class
# plain old ruby class, no active record involved
class MampfMatrix
  include ActiveModel::Model
  include ActiveModel::Validations
  validate :matching_dimensions?
  validate :valid_entries?

  attr_accessor :domain, :column_count, :row_count, :coefficients

  def equals?(other_matrix)
    return false unless @domain == other_matrix.domain
    return false unless @column_count = other_matrix.column_count
    return false unless @row_count = other_matrix.row_count
    @coefficients.each_with_index do |c,i|
      return false unless c.equals?(other_matrix.coefficients[i])
    end
    true
  end

  def entry(i,j)
    if i > @row_count || j > @column_count
      return domain.constantize.trivial_instance
    end
    @coefficients[(i - 1) *  @column_count + (j - 1)]
  end

  def self.trivial_instance
    self.new(row_count: 2, column_count: 2,
                           domain: 'MampfNumber',
                           coefficients:
                             (1..4).map { |i| MampfNumber.trivial_instance })
  end

  def matching_dimensions?
    return true if @coefficients.count == column_count * row_count
    errors.add(:base, I18n.t('math.wrong_matrix_dimensions'))
    false
  end

  def valid_entries?
    return true if @coefficients.all?(&:valid?)
    errors.add(:base, I18n.t('math.matrix_bad_coefficients'))
  end

  def to_tex
    ''
  end
end
