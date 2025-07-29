module Filters
  class TeachableFilter < BaseFilter
    def call
      # The TeachableParser handles the logic for `all_teachables` and
      # `teachable_inheritance`. It returns the correct list of teachable
      # strings to filter by.
      parser = TeachableParser.new(params)
      teachable_id_strings = parser.teachables_as_strings

      # If the parser returns an empty list (e.g., 'all teachables' was
      # selected or no teachables were provided), we don't apply any filter.
      return scope if teachable_id_strings.blank?

      # The teachable_ids are strings like "Course-1", "Lecture-5"
      conditions = teachable_id_strings.map do |id_string|
        type, id = id_string.split("-")
        "(teachable_type = '#{type}' AND teachable_id = #{id.to_i})"
      end

      scope.where(conditions.join(" OR "))
    end
  end
end
