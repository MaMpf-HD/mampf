class CacheInvalidatorService
  # Declarative map of all dependencies. This is now the single source of truth.
  # The SQL query is generated from this map.
  #
  # Format:
  # SourceModel => [
  #   { to: DestinationModel, type: :belongs_to, fk: :foreign_key_on_source },
  #   { to: DestinationModel, type: :has_many, fk: :foreign_key_on_destination },
  #   { to: DestinationModel, type: :has_many, through: :join_table_name },
  #   { to: DestinationModel, type: :polymorphic_has_many, as: :teachable },
  # ]
  DEPENDENCY_MAP = {
    Course => [
      { to: Lecture, type: :has_many, fk: :course_id },
      { to: Medium, type: :polymorphic_has_many, as: :teachable },
      { to: Tag, type: :has_many, through: :course_tag_joins }
    ],
    Lecture => [
      { to: Course, type: :belongs_to, fk: :course_id },
      { to: Chapter, type: :has_many, fk: :lecture_id },
      { to: Lesson, type: :has_many, fk: :lecture_id },
      { to: Talk, type: :has_many, fk: :lecture_id },
      { to: Medium, type: :polymorphic_has_many, as: :teachable }
    ],
    Chapter => [
      { to: Lecture, type: :belongs_to, fk: :lecture_id },
      { to: Section, type: :has_many, fk: :chapter_id }
    ],
    Section => [
      { to: Chapter, type: :belongs_to, fk: :chapter_id },
      { to: Lesson, type: :has_many, through: :lesson_section_joins },
      { to: Tag, type: :has_many, through: :section_tag_joins }
    ],
    Lesson => [
      { to: Lecture, type: :belongs_to, fk: :lecture_id },
      { to: Section, type: :has_many, through: :lesson_section_joins },
      { to: Medium, type: :polymorphic_has_many, as: :teachable },
      { to: Tag, type: :has_many, through: :lesson_tag_joins }
    ],
    Talk => [
      { to: Lecture, type: :belongs_to, fk: :lecture_id },
      { to: Medium, type: :polymorphic_has_many, as: :teachable },
      { to: Tag, type: :has_many, through: :talk_tag_joins }
    ],
    Medium => [
      { to: :teachable, type: :polymorphic_belongs_to, as: :teachable },
      { to: Tag, type: :has_many, through: :medium_tag_joins }
    ],
    Tag => [
      { to: Course, type: :has_many, through: :course_tag_joins },
      { to: Section, type: :has_many, through: :section_tag_joins },
      { to: Lesson, type: :has_many, through: :lesson_tag_joins },
      { to: Talk, type: :has_many, through: :talk_tag_joins },
      { to: Medium, type: :has_many, through: :medium_tag_joins },
      { to: Tag, type: :has_many, through: :relations, fk: :tag_id, assoc_fk: :related_tag_id }
    ]
  }.freeze

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

      # Generates the large EDGES_SQL string from the DEPENDENCY_MAP and memoizes it.
      def edges_sql
        @edges_sql ||= DEPENDENCY_MAP.flat_map do |src_model, dependencies|
          dependencies.map do |dep|
            generate_sql_for_dependency(src_model, dep)
          end
        end.compact.join("\nUNION ALL\n")
      end

      def generate_sql_for_dependency(src_model, dep)
        src_table = src_model.table_name
        dst_model = dep[:to]

        case dep[:type]
        when :belongs_to
          <<~SQL.squish
            SELECT '#{src_model}' AS src_type,
                   #{src_table}.id AS src_id,
                   '#{dst_model}' AS dst_type,
                   #{src_table}.#{dep[:fk]} AS dst_id
            FROM #{src_table}
          SQL
        when :has_many
          if dep[:through]
            join_table = dep[:through]
            src_fk = dep[:fk] || "#{src_model.name.underscore}_id"
            dst_fk = dep[:assoc_fk] || "#{dst_model.name.underscore}_id"
            <<~SQL.squish
              SELECT '#{src_model}' AS src_type,
                     #{src_fk} AS src_id,
                     '#{dst_model}' AS dst_type,
                     #{dst_fk} AS dst_id
              FROM #{join_table}
            SQL
          else
            dst_table = dst_model.table_name
            <<~SQL.squish
              SELECT '#{src_model}' AS src_type,
                     #{src_table}.id AS src_id,
                     '#{dst_model}' AS dst_type,
                     #{dst_table}.id AS dst_id
              FROM #{src_table}
              JOIN #{dst_table} ON #{dst_table}.#{dep[:fk]} = #{src_table}.id
            SQL
          end
        when :polymorphic_has_many
          dst_table = dst_model.table_name
          <<~SQL.squish
            SELECT '#{src_model}' AS src_type,
                   #{src_table}.id AS src_id,
                   '#{dst_model}' AS dst_type,
                   #{dst_table}.id AS dst_id
            FROM #{src_table}
            JOIN #{dst_table}
              ON #{dst_table}.#{dep[:as]}_id = #{src_table}.id
             AND #{dst_table}.#{dep[:as]}_type = '#{src_model}'
          SQL
        when :polymorphic_belongs_to
          <<~SQL.squish
            SELECT '#{src_model}' AS src_type,
                   #{src_table}.id AS src_id,
                   #{src_table}.#{dep[:as]}_type AS dst_type,
                   #{src_table}.#{dep[:as]}_id AS dst_id
            FROM #{src_table}
            WHERE #{src_table}.#{dep[:as]}_id IS NOT NULL
          SQL
        end
      end

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
            JOIN (#{edges_sql}) AS edges ON edges.src_type = dependencies.type AND edges.src_id = dependencies.id
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
        rows.group_by { |row| row["type"]&.constantize }.compact
            .transform_values { |value| value.map { |row| row["id"] } }
      end
  end
end
