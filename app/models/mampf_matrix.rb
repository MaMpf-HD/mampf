# MampfMatrix class
# plain old ruby class, no active record involved
class MampfMatrix
  include ActiveModel::Model

  attr_accessor :column_count, :row_count, :coefficients, :tex

  def equals?(other_matrix)
    return false unless @column_count = other_matrix.column_count
    return false unless @row_count = other_matrix.row_count
    @coefficients.each_with_index do |c, i|
      return false unless c.equals?(other_matrix.coefficients[i])
    end
    true
  end

  def self.trivial_instance
    self.new(row_count: 2, column_count: 2,
                           coefficients: ['0', '0', '0', '0'],
                           tex: '\begin{pmatrix} 0 & 0 \cr 0 & 0 \end{pmatrix}')
  end

  def entry(i,j)
    if i > @row_count || j > @column_count
      return '0'
    end
    @coefficients[(i - 1) *  @column_count + (j - 1)]
  end

  def self.from_hash(content)
    row_count = content['row_count'].to_i
    column_count = content['column_count'].to_i
    tex = content['tex']
    coefficients = []
    (1..row_count).each do |i|
      (1..column_count).each do |j|
        coefficients.push(content["#{i},#{j}"])
      end
    end
    MampfMatrix.new(row_count: row_count,
                    column_count: column_count,
                    coefficients: coefficients,
                    tex: tex)
  end
end
