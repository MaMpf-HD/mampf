class CacheInvalidatorService
  # This single SQL statement defines all directed edges in the dependency graph.
  # It replaces the RESOLVERS hash. Each SELECT represents a relationship.
  # The structure is: SELECT 'SourceModel', source_id, 'DestinationModel', destination_id FROM ...
  EDGES_SQL = <<-SQL.freeze
    -- Course dependencies
    SELECT 'Course' AS src_type, courses.id AS src_id, 'Lecture' AS dst_type, lectures.id AS dst_id FROM courses JOIN lectures ON lectures.course_id = courses.id
    UNION ALL
    SELECT 'Course' AS src_type, courses.id AS src_id, 'Medium' AS dst_type, media.id AS dst_id FROM courses JOIN media ON media.teachable_id = courses.id AND media.teachable_type = 'Course'
    UNION ALL
    SELECT 'Course' AS src_type, course_id AS src_id, 'Tag' AS dst_type, tag_id AS dst_id FROM course_tag_joins

    -- Lecture dependencies
    UNION ALL
    SELECT 'Lecture' AS src_type, lectures.id AS src_id, 'Course' AS dst_type, course_id AS dst_id FROM lectures
    UNION ALL
    SELECT 'Lecture' AS src_type, lectures.id AS src_id, 'Chapter' AS dst_type, chapters.id AS dst_id FROM lectures JOIN chapters ON chapters.lecture_id = lectures.id
    UNION ALL
    SELECT 'Lecture' AS src_type, lectures.id AS src_id, 'Lesson' AS dst_type, lessons.id AS dst_id FROM lectures JOIN lessons ON lessons.lecture_id = lectures.id
    UNION ALL
    SELECT 'Lecture' AS src_type, lectures.id AS src_id, 'Talk' AS dst_type, talks.id AS dst_id FROM lectures JOIN talks ON talks.lecture_id = lectures.id
    UNION ALL
    SELECT 'Lecture' AS src_type, lectures.id AS src_id, 'Medium' AS dst_type, media.id AS dst_id FROM lectures JOIN media ON media.teachable_id = lectures.id AND media.teachable_type = 'Lecture'

    -- Chapter dependencies
    UNION ALL
    SELECT 'Chapter' AS src_type, chapters.id AS src_id, 'Lecture' AS dst_type, lecture_id AS dst_id FROM chapters
    UNION ALL
    SELECT 'Chapter' AS src_type, chapters.id AS src_id, 'Section' AS dst_type, sections.id AS dst_id FROM chapters JOIN sections ON sections.chapter_id = chapters.id

    -- Section dependencies
    UNION ALL
    SELECT 'Section' AS src_type, sections.id AS src_id, 'Chapter' AS dst_type, chapter_id AS dst_id FROM sections
    UNION ALL
    SELECT 'Section' AS src_type, section_id AS src_id, 'Lesson' AS dst_type, lesson_id AS dst_id FROM lesson_section_joins
    UNION ALL
    SELECT 'Section' AS src_type, section_id AS src_id, 'Tag' AS dst_type, tag_id AS dst_id FROM section_tag_joins

    -- Lesson dependencies
    UNION ALL
    SELECT 'Lesson' AS src_type, lessons.id AS src_id, 'Lecture' AS dst_type, lecture_id AS dst_id FROM lessons
    UNION ALL
    SELECT 'Lesson' AS src_type, lesson_id AS src_id, 'Section' AS dst_type, section_id AS dst_id FROM lesson_section_joins
    UNION ALL
    SELECT 'Lesson' AS src_type, lessons.id AS src_id, 'Medium' AS dst_type, media.id AS dst_id FROM lessons JOIN media ON media.teachable_id = lessons.id AND media.teachable_type = 'Lesson'
    UNION ALL
    SELECT 'Lesson' AS src_type, lesson_id AS src_id, 'Tag' AS dst_type, tag_id AS dst_id FROM lesson_tag_joins

    -- Talk dependencies
    UNION ALL
    SELECT 'Talk' AS src_type, talks.id AS src_id, 'Lecture' AS dst_type, lecture_id AS dst_id FROM talks
    UNION ALL
    SELECT 'Talk' AS src_type, talks.id AS src_id, 'Medium' AS dst_type, media.id AS dst_id FROM talks JOIN media ON media.teachable_id = talks.id AND media.teachable_type = 'Talk'
    UNION ALL
    SELECT 'Talk' AS src_type, talk_id AS src_id, 'Tag' AS dst_type, tag_id AS dst_id FROM talk_tag_joins

    -- Medium dependencies
    UNION ALL
    SELECT 'Medium' AS src_type, media.id AS src_id, teachable_type AS dst_type, teachable_id AS dst_id FROM media WHERE teachable_id IS NOT NULL
    UNION ALL
    SELECT 'Medium' AS src_type, medium_id AS src_id, 'Tag' AS dst_type, tag_id AS dst_id FROM medium_tag_joins

    -- Tag dependencies
    UNION ALL
    SELECT 'Tag' AS src_type, tag_id AS src_id, 'Course' AS dst_type, course_id AS dst_id FROM course_tag_joins
    UNION ALL
    SELECT 'Tag' AS src_type, tag_id AS src_id, 'Section' AS dst_type, section_id AS dst_id FROM section_tag_joins
    UNION ALL
    SELECT 'Tag' AS src_type, tag_id AS src_id, 'Lesson' AS dst_type, lesson_id AS dst_id FROM lesson_tag_joins
    UNION ALL
    SELECT 'Tag' AS src_type, tag_id AS src_id, 'Talk' AS dst_type, talk_id AS dst_id FROM talk_tag_joins
    UNION ALL
    SELECT 'Tag' AS src_type, tag_id AS src_id, 'Medium' AS dst_type, medium_id AS dst_id FROM medium_tag_joins
    UNION ALL
    SELECT 'Tag' AS src_type, tag_id AS src_id, 'Tag' AS dst_type, related_tag_id AS dst_id FROM relations
  SQL

  class << self
    def run(model)
      # Get all dependent items in a single query.
      buckets = closure_from(model.class.base_class.name, model.id)

      # Add the initial model to the list of items to be updated.
      buckets.fetch(model.class.base_class, []) << model.id

      timestamp = Time.current
      buckets.each do |klass, ids|
        next if ids.empty?

        # rubocop:disable Rails/SkipsModelValidations
        klass.where(id: ids.uniq).update_all(updated_at: timestamp)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    private

      # Executes the recursive CTE to find all dependencies.
      def closure_from(start_type, start_id)
        sql = <<~SQL
          WITH RECURSIVE dependencies(type, id) AS (
            -- Base case: the starting object
            SELECT $1::text, $2::bigint
            UNION
            -- Recursive step: join dependencies with the edges
            SELECT edges.dst_type, edges.dst_id
            FROM dependencies
            JOIN (
              SELECT src_type, src_id, dst_type, dst_id FROM (#{EDGES_SQL}) AS all_edges
            ) AS edges ON edges.src_type = dependencies.type AND edges.src_id = dependencies.id
          )
          SELECT type, id FROM dependencies;
        SQL

        # exec_query returns an array of hashes, e.g. [{'type' => 'Course', 'id' => 1}, ...]
        rows = ActiveRecord::Base.connection.exec_query(
          sql,
          "cache_invalidator_closure",
          [start_type, start_id]
        )

        # Group the results by class name.
        rows.group_by { |row| row["type"].constantize }
            .transform_values { |value| value.map { |row| row["id"] } }
      end
  end
end
