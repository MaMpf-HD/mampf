# Extensions of String class
class String
  def string_between_markers(marker1, marker2)
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end

  def to_h
    array = gsub(/[{}:]/, '').split(', ')
    hash = {}
    array.each do |e|
      key_string, value_string = e.split('=>')
      key = key_string.to_i
      value = value_string == 'true'
      hash[key] = value
    end
    hash
  end

  def range?
    self.match(/\[-?\d+..-?\d+\]/).present?
  end

  def to_a_or_range
    stripped = gsub(/[\[\]]/, '')
    return stripped.split(',') - [''] unless range?
    bounds = stripped.split('..').map(&:to_i)
    (bounds[0]..bounds[1])
  end
end
