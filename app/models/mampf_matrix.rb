# MampfMatrix class
# plain old ruby class, no active record involved
class MampfMatrix
  include ActiveModel::Model

  attr_accessor :domain, :column_count, :row_count, :coefficients

  def equals?(other_matrix)
    return false unless @domain == other_matrix.domain
    return false unless @column_count = other_matrix.column_count
    return false unless @row_count = other_matrix.row_count
    @coefficients.each_with_index do |c, i|
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
                           domain: 'MampfExpression',
                           coefficients:
                             (1..4).map { |i| MampfExpression.trivial_instance })
  end

  def to_tex
    entries = ''
    (1..row_count).each do |i|
      (1..column_count).each do |j|
        entries += entry(i,j).to_tex
        entries += '&' unless j == column_count
        entries += '\\\\' if j == column_count && i != row_count
      end
    end
    '\\begin{pmatrix}' + entries + '\\end{pmatrix}'
  end

  def self.from_hash(content)
    row_count = content['row_count'].to_i
    column_count = content['column_count'].to_i
    domain = content['domain']
    if domain == 'MampfExpression'
      coefficients = []
      (1..row_count).each do |i|
        (1..column_count).each do |j|
          coefficients.push(MampfExpression.new(content["#{i},#{j}"]))
        end
      end
      MampfMatrix.new(row_count: row_count,
                      column_count: column_count,
                      domain: domain,
                      coefficients: coefficients)
    end
  end
end
