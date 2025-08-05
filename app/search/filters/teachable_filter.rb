# Filters media by their specific teachable parent (e.g., a Course or Lecture).
#
# This filter is skipped if no teachable parameters are provided.
#
# It relies on the `TeachableParser` to extract a list of teachable
# identifiers (e.g., "Course-1", "Lecture-5") from the request parameters.
# For each valid identifier, it constructs an Arel condition to match the
# `teachable_type` and `teachable_id`. These conditions are then combined
# with OR to find all media that belong to any of the specified teachables.
module Search
  module Filters
    class TeachableFilter < BaseFilter
      def call
        # This single check handles nil, [], [""], [nil], etc.
        no_specific_teachables = params[:teachable_ids].to_a.compact_blank.empty?

        return scope if no_specific_teachables

        conditions = build_arel_conditions

        # If params were provided but none were valid, return an empty scope.
        return scope.none if conditions.blank?

        # Chain all individual conditions together with OR.
        combined_conditions = conditions.reduce(:or)
        scope.where(combined_conditions)
      end

      private

        # Builds an array of Arel conditions based on the teachable parameters.
        #
        # @return [Array<Arel::Node>] An array of conditions, or an empty array.
        def build_arel_conditions
          teachable_id_strings = TeachableParser.call(params)
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
end
