class Array
  def percentile(wanted_percentile)
    sorted_array = sort

    index = (wanted_percentile.to_f / 100) * sorted_array.length - 1

    if index != index.to_i
      sorted_array.at(index.ceil)
    elsif sorted_array.length.even?
      first_value = sorted_array.at(index)
      second_value = sorted_array.at(index + 1)
      (first_value + second_value) / 2
    else
      sorted_array.at(index)
    end
  end
end