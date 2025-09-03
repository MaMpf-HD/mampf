# Search Helper

module SearchHelper
  def hits_per_page(results_as_list)
    return [[10, 10], [20, 20], [50, 50]] if results_as_list

    [[3, 3], [4, 4], [6, 6], [12, 12]]
  end

  def default_hits_per_page(results_as_list)
    return 20 if results_as_list

    6
  end
end
