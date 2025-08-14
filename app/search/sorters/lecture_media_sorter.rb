# This sorter replicates the complex, multi-stage sorting logic from the
# legacy MediaController#search_results method.
#
# The desired order is:
# 1. "Native" media, sorted by their teachable type:
#    - Media on the Lecture itself (by creation date)
#    - Media on Lessons (by lesson date, then position)
#    - Media on Talks (by talk position)
#    - Media on the Course (by description)
# 2. Imported media, appended at the end.
module Search
  module Sorters
    class LectureMediaSorter < BaseSorter
      def call
        lecture = Lecture.find_by(id: search_params[:id])
        return scope.order(model_class.default_search_order) unless lecture

        # Get Arel table references for building the query.
        media_table = Medium.arel_table

        # Create aliased table references to ensure stable names in the query.
        lessons_table = Lesson.arel_table.alias("_search_lessons_media")
        talks_table = Talk.arel_table.alias("_search_talks_media")

        # Build the join nodes manually using the aliased tables.
        lessons_join = Arel::Nodes::OuterJoin.new(
          lessons_table,
          Arel::Nodes::On.new(
            media_table[:teachable_type].eq("Lesson")
            .and(media_table[:teachable_id]
            .eq(lessons_table[:id]))
          )
        )
        talks_join = Arel::Nodes::OuterJoin.new(
          talks_table,
          Arel::Nodes::On.new(
            media_table[:teachable_type].eq("Talk")
            .and(media_table[:teachable_id]
            .eq(talks_table[:id]))
          )
        )

        # Pre-fetch the imported media IDs into an array to avoid subquery
        # issues with bind parameters when ActiveRecord builds its COUNT query.
        imported_media_ids = lecture.imported_media.pluck(:id)

        # Determine sort direction for lessons based on the lecture's term.
        lesson_sort_dir = determine_lesson_sort_direction(lecture)

        # Define the complex sorting expressions using Arel's CASE statements.
        # These will be used for both SELECTing and ORDERING.
        sort_expressions = {
          sort_group1: Arel::Nodes::Case.new
                                        .when(media_table[:id].in(imported_media_ids)).then(2)
                                        .else(1),
          sort_group2: Arel::Nodes::Case.new(media_table[:teachable_type])
                                        .when("Lecture").then(1)
                                        .when("Lesson").then(2)
                                        .when("Talk").then(3)
                                        .when("Course").then(4)
                                        .else(5),
          sort_lecture_created_at: Arel::Nodes::Case.new
                                                    .when(media_table[:teachable_type]
                                                    .eq("Lecture")).then(media_table[:created_at]),
          sort_lesson_date: Arel::Nodes::Case.new
                                             .when(media_table[:teachable_type]
                                             .eq("Lesson")).then(lessons_table[:date]),
          sort_lesson_id: Arel::Nodes::Case.new
                                           .when(media_table[:teachable_type]
                                           .eq("Lesson")).then(lessons_table[:id]),
          sort_lesson_position: Arel::Nodes::Case.new
                                                 .when(media_table[:teachable_type]
                                                 .eq("Lesson")).then(media_table[:position]),
          sort_talk_position: Arel::Nodes::Case.new
                                               .when(media_table[:teachable_type]
                                               .eq("Talk")).then(talks_table[:position]),
          sort_course_description: Arel::Nodes::Case.new
                                                    .when(media_table[:teachable_type]
                                                    .eq("Course")).then(media_table[:description])
        }

        # Build the final order clause using the Arel expressions.
        order_clause = [
          sort_expressions[:sort_group1].asc,
          sort_expressions[:sort_group2].asc,
          sort_expressions[:sort_lecture_created_at].desc,
          sort_expressions[:sort_lesson_date].send(lesson_sort_dir),
          sort_expressions[:sort_lesson_id].send(lesson_sort_dir),
          sort_expressions[:sort_lesson_position].asc,
          sort_expressions[:sort_talk_position].asc,
          sort_expressions[:sort_course_description].asc
        ]

        # Join the necessary tables for sorting.
        # Select the original columns plus our new aliased sort expressions.
        # Order by the Arel expressions.
        scope
          .joins(lessons_join)
          .joins(talks_join)
          .select(media_table[Arel.star], *sort_expressions.map { |k, v| v.as(k.to_s) })
          .order(order_clause)
      end

      private

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
