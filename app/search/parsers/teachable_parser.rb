# This service object is responsible for parsing and expanding a list of
# "teachable" identifiers provided in search parameters.
#
# It returns a hash grouping the teachable IDs by their class name, which can
# be used to build an efficient database query.
#
# When inheritance is enabled, it uses efficient subqueries to find all
# child teachables (e.g., lectures and lessons under a given course) without
# loading the full records into memory.
#
# Example with inheritance:
#
# Given `params[:teachable_ids]` = `["Course-1", "Lecture-5"]` and
# `params[:teachable_inheritance]` = `"1"`, the parser will return a hash
# containing:
# - "Course" => [1]
# - "Lecture" => An ActiveRecord::Relation subquery for all lectures in course 1
#                plus lecture 5.
# - "Lesson" => An ActiveRecord::Relation subquery for all lessons belonging
#               to the lectures found above.
#
module Search
  module Parsers
    class TeachableParser
      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @teachable_ids = params[:teachable_ids].to_a.compact_blank
        @all_teachables = params[:all_teachables] == "1"
        @inheritance = params[:teachable_inheritance] == "1"
      end

      # @return [Hash{String => Array<Integer>}] A hash like {"Course" => [1, 7]}
      def call
        return {} if @all_teachables || @teachable_ids.empty?
        return group_simple_teachables unless @inheritance

        group_teachables_with_inheritance
      end

      private

        # Groups IDs from strings without inheritance logic.
        def group_simple_teachables
          @teachable_ids.each_with_object(Hash.new { |h, k| h[k] = [] }) do |id_string, hash|
            type, id = id_string.split("-", 2)
            hash[type] << id.to_i if type.in?(["Course", "Lecture", "Lesson"]) && id.present?
          end
        end

        # Gathers all teachable IDs with inheritance using efficient subqueries.
        def group_teachables_with_inheritance
          simple_groups = group_simple_teachables
          course_ids = simple_groups.fetch("Course", [])
          lecture_ids = simple_groups.fetch("Lecture", [])
          lesson_ids = simple_groups.fetch("Lesson", [])

          lectures_subquery = build_lectures_subquery(course_ids, lecture_ids)
          lessons_result = build_lessons_result(lectures_subquery, lesson_ids)

          # If no courses or lectures were given, the lesson part will be a
          # subquery. If the user only selected lessons, we can just return the array.
          final_lessons = if course_ids.empty? && lecture_ids.empty?
            lesson_ids
          else
            lessons_result
          end

          {
            "Course" => course_ids,
            "Lecture" => lectures_subquery,
            "Lesson" => final_lessons
          }
        end

        # Builds a subquery for lectures that were explicitly selected OR belong
        # to selected courses.
        def build_lectures_subquery(course_ids, lecture_ids)
          Lecture.where(id: lecture_ids)
                 .or(Lecture.where(course_id: course_ids))
                 .select(:id)
        end

        # Builds a subquery for lessons that belong to the given lectures OR were
        # explicitly selected.
        def build_lessons_result(lectures_subquery, lesson_ids)
          Lesson.where(lecture_id: lectures_subquery)
                .or(Lesson.where(id: lesson_ids))
                .select(:id)
        end
    end
  end
end
