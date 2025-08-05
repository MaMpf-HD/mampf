# This service object is responsible for parsing and expanding a list of
# "teachable" identifiers provided in search parameters.
#
# Its primary purpose is to handle the "inheritance" logic for teachables.
# When a user selects a course and enables inheritance, this parser finds not
# only the course itself but also all associated lectures and lessons.
#
# It is designed to be efficient, using a minimal number of database queries
# to gather all related records.
#
# @example
#   params = {
#     teachable_ids: ["Course-1"],
#     teachable_inheritance: "1"
#   }
#   Search::TeachableParser.call(params)
#   # => ["Course-1", "Lecture-10", "Lecture-11", "Lesson-101", ...]
#
module Search
  class TeachableParser
    # Convenience class method to initialize and call the parser in one step.
    def self.call(params)
      new(params).call
    end

    # Initializes the parser with parameters from a search request.
    #
    # @param params [Hash] A hash that may contain the following keys:
    #   - :teachable_ids [Array<String>] An array of teachable identifiers
    #     (e.g., ["Course-1", "Lecture-5"]).
    #   - :all_teachables [String] If "1", signals that filtering by teachable
    #     should be skipped.
    #   - :teachable_inheritance [String] If "1", expands the scope to include
    #     child teachables (e.g., lectures and lessons under a given course).
    def initialize(params)
      @teachable_ids = params[:teachable_ids] || []
      @all_teachables = params[:all_teachables] == "1"
      @inheritance = params[:teachable_inheritance] == "1"
    end

    # Performs the parsing logic based on the initialized parameters.
    #
    # This method resolves a list of teachable identifiers (e.g., "Course-1").
    # - If the `all_teachables` flag was set, it returns an empty array to
    #   signal that filtering should be skipped.
    # - If `inheritance` is disabled, it returns the original list of IDs.
    # - If `inheritance` is enabled, it expands the list to include child
    #   teachables (e.g., lectures and lessons under a given course).
    #
    # @return [Array<String>] An array of teachable identifiers.
    def call
      return [] if @all_teachables
      return @teachable_ids unless @inheritance

      teachables_with_inheritance.map { |t| "#{t.class.name}-#{t.id}" }
    end

    private

      # Memoized parsing of lecture IDs from the input strings.
      def lecture_ids
        @lecture_ids ||= @teachable_ids.filter_map do |t|
          t.delete_prefix("Lecture-").to_i if t.start_with?("Lecture-")
        end
      end

      # Memoized parsing of course IDs from the input strings.
      def course_ids
        @course_ids ||= @teachable_ids.filter_map do |t|
          t.delete_prefix("Course-").to_i if t.start_with?("Course-")
        end
      end

      # Finds all specified courses in a single query.
      def courses
        @courses ||= Course.where(id: course_ids)
      end

      # Finds all specified lectures and lectures from specified courses
      # in a single, efficient query using OR.
      def lectures_with_inheritance
        @lectures_with_inheritance ||=
          Lecture.where(id: lecture_ids).or(Lecture.where(course_id: course_ids))
      end

      # Finds all lessons belonging to the relevant lectures in a single query,
      # avoiding N+1 problems.
      def lessons_with_inheritance
        @lessons_with_inheritance ||= Lesson.where(lecture: lectures_with_inheritance)
      end

      # Gathers all teachable records. Each method call triggers at most one
      # efficient query.
      def teachables_with_inheritance
        # The '+' operator on relations will trigger the queries and return an array.
        courses.to_a + lectures_with_inheritance.to_a + lessons_with_inheritance.to_a
      end
  end
end
