module Search
  module Sorters
    class LectureMediaSorter < BaseSorter
      def sort
        # Use a local variable for the initial lookup.
        found_lecture = Lecture.find_by(id: search_params[:id])
        return scope.order(model_class.default_search_order) unless found_lecture

        # Set up the instance variables that the private readers will expose.
        @lecture = found_lecture
        @media_table = Medium.arel_table
        @lessons_table = Lesson.arel_table.alias("_search_lessons_media")
        @talks_table = Talk.arel_table.alias("_search_talks_media")
        @imported_media_ids = lecture.imported_media.pluck(:id)

        sort_expressions = build_sort_expressions
        order_clause = build_order_clause(sort_expressions)

        scope
          .joins(lessons_join)
          .joins(talks_join)
          .select(media_table[Arel.star], *sort_expressions.map { |k, v| v.as(k.to_s) })
          .order(order_clause)
      end

      private

        attr_reader :lecture, :media_table, :lessons_table, :talks_table, :imported_media_ids

        # Builds the Arel node for the outer join on the lessons table.
        def lessons_join
          Arel::Nodes::OuterJoin.new(
            lessons_table,
            Arel::Nodes::On.new(
              media_table[:teachable_type].eq("Lesson")
              .and(media_table[:teachable_id].eq(lessons_table[:id]))
            )
          )
        end

        # Builds the Arel node for the outer join on the talks table.
        def talks_join
          Arel::Nodes::OuterJoin.new(
            talks_table,
            Arel::Nodes::On.new(
              media_table[:teachable_type].eq("Talk")
              .and(media_table[:teachable_id].eq(talks_table[:id]))
            )
          )
        end

        # Constructs a hash of named Arel CASE statements that will be used
        # for both SELECTing the sort values and for ordering.
        def build_sort_expressions
          {
            sort_group1: sort_group1_expression,
            sort_group2: sort_group2_expression,
            sort_lecture_created_at: sort_by_teachable_expression("Lecture",
                                                                  media_table[:created_at]),
            sort_lesson_date: sort_by_teachable_expression("Lesson", lessons_table[:date]),
            sort_lesson_id: sort_by_teachable_expression("Lesson", lessons_table[:id]),
            sort_lesson_position: sort_by_teachable_expression("Lesson", media_table[:position]),
            sort_talk_position: sort_by_teachable_expression("Talk", talks_table[:position]),
            sort_course_description: sort_by_teachable_expression("Course",
                                                                  media_table[:description])
          }
        end

        # Assembles the final ORDER BY clause from the sort expressions.
        def build_order_clause(sort_expressions)
          lesson_sort_dir = determine_lesson_sort_direction(lecture)
          [
            sort_expressions[:sort_group1].asc,
            sort_expressions[:sort_group2].asc,
            sort_expressions[:sort_lecture_created_at].desc,
            sort_expressions[:sort_lesson_date].send(lesson_sort_dir),
            sort_expressions[:sort_lesson_id].send(lesson_sort_dir),
            sort_expressions[:sort_lesson_position].asc,
            sort_expressions[:sort_talk_position].asc,
            sort_expressions[:sort_course_description].asc
          ]
        end

        # CASE statement to separate imported media (group 2) from native media (group 1).
        def sort_group1_expression
          Arel::Nodes::Case.new
                           .when(media_table[:id].in(imported_media_ids)).then(2)
                           .else(1)
        end

        # CASE statement to group media by their teachable type.
        def sort_group2_expression
          Arel::Nodes::Case.new(media_table[:teachable_type])
                           .when("Lecture").then(1)
                           .when("Lesson").then(2)
                           .when("Talk").then(3)
                           .when("Course").then(4)
                           .else(5)
        end

        # Generic helper to create a CASE statement that returns a specific
        # column's value only when the teachable_type matches.
        def sort_by_teachable_expression(type, column)
          Arel::Nodes::Case.new
                           .when(media_table[:teachable_type].eq(type)).then(column)
        end

        # Determines the sort direction for lessons. For the active term or for
        # term-independent lectures, lessons are sorted newest-first (desc).
        # For all other (older) terms, they are sorted chronologically (asc).
        def determine_lesson_sort_direction(lecture)
          if lecture.term.blank? || lecture.term.active?
            :desc
          else
            :asc
          end
        end
    end
  end
end
