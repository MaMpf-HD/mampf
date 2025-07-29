module Filters
  class TeachableFilter < BaseFilter
    def call
      conditions = build_arel_conditions
      return scope if conditions.blank?

      # Chain all individual conditions together with OR.
      combined_conditions = conditions.reduce(:or)
      scope.where(combined_conditions)
    end

    private

      # Builds an array of Arel conditions based on the teachable parameters.
      #
      # @return [Array<Arel::Node>] An array of conditions, or an empty array.
      def build_arel_conditions
        teachable_id_strings = TeachableParser.new(params).teachables_as_strings
        return [] if teachable_id_strings.blank?

        media = Medium.arel_table
        allowed_types = ["Course", "Lecture", "Lesson"]

        teachable_id_strings.filter_map do |id_string|
          type, id = id_string.split("-", 2)

          # Ensure the type is one of the allowed polymorphic types.
          if type.in?(allowed_types)
            media[:teachable_type].eq(type).and(media[:teachable_id].eq(id.to_i))
          end
        end
      end
  end
end
