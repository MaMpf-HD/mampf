# MampfMatrix class
# plain old ruby class, no active record involved
class MampfMatrix
  attr_reader :column_count, :row_count, :coefficients, :tex, :nerd

  def initialize(row_count, column_count, coefficients, tex, nerd)
    @row_count = row_count
    @column_count = column_count
    @coefficients = coefficients
    @tex = tex
    @nerd = nerd
  end

  def self.trivial_instance
    self.new(2, 2,
             ['0', '0', '0', '0'],
             '\begin{pmatrix} 0 & 0 \cr 0 & 0 \end{pmatrix}',
             'matrix([0,0],[0,0]')
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
    nerd = content['nerd']
    coefficients = []
    (1..row_count).each do |i|
      (1..column_count).each do |j|
        coefficients.push(content["#{i},#{j}"])
      end
    end
    MampfMatrix.new(row_count, column_count, coefficients, tex, nerd)
  end
end
