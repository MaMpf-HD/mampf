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
  #   { to: :polymorphic_assoc, type: :polymorphic_belongs_to, as: :association_name },
  #   { to: BaseModel, type: :sti_identity } # For Single Table Inheritance
  # ]
  #
  # NOTE: Join tables (e.g., CourseTagJoin) do not need to be listed as a main
  # key in this map. They are automatically detected and processed if they appear
  # in a `:through` option in another entry.
  DEPENDENCY_MAP = {
    Answer => [
      { to: Question, type: :belongs_to, fk: :question_id }
    ],
    Assignment => [
      { to: Lecture, type: :belongs_to, fk: :lecture_id }
    ],
    Question => [
      { to: Medium, type: :sti_identity }
    ],
    Course => [
      { to: Lecture, type: :has_many, fk: :course_id },
      { to: Medium, type: :polymorphic_has_many, as: :teachable },
      { to: Tag, type: :has_many, through: :course_tag_joins },
      { to: Medium, type: :has_many, through: :imports, fk: :teachable_id, assoc_fk: :medium_id }
    ],
    Lecture => [
      { to: Course, type: :belongs_to, fk: :course_id },
      { to: Chapter, type: :has_many, fk: :lecture_id },
      { to: Lesson, type: :has_many, fk: :lecture_id },
      { to: Talk, type: :has_many, fk: :lecture_id },
      { to: Medium, type: :polymorphic_has_many, as: :teachable },
      { to: Assignment, type: :has_many, fk: :lecture_id },
      { to: Medium, type: :has_many, through: :imports, fk: :teachable_id, assoc_fk: :medium_id }
    ],
    Chapter => [
      { to: Lecture, type: :belongs_to, fk: :lecture_id },
      { to: Section, type: :has_many, fk: :chapter_id }
    ],
    Section => [
      { to: Chapter, type: :belongs_to, fk: :chapter_id },
      { to: Lesson, type: :has_many, through: :lesson_section_joins },
      { to: Tag, type: :has_many, through: :section_tag_joins },
      { to: Item, type: :has_many, fk: :section_id }
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
      { to: Tag, type: :has_many, through: :medium_tag_joins },
      { to: Item, type: :has_many, fk: :medium_id },
      { to: Item, type: :has_many, through: :referrals },
      { to: Medium, type: :has_many, through: :links, fk: :medium_id,
        assoc_fk: :linked_medium_id },
      { to: Course, type: :has_many, through: :imports, fk: :medium_id, assoc_fk: :teachable_id },
      { to: Lecture, type: :has_many, through: :imports, fk: :medium_id, assoc_fk: :teachable_id }
    ],
    Tag => [
      { to: Course, type: :has_many, through: :course_tag_joins },
      { to: Section, type: :has_many, through: :section_tag_joins },
      { to: Lesson, type: :has_many, through: :lesson_tag_joins },
      { to: Talk, type: :has_many, through: :talk_tag_joins },
      { to: Medium, type: :has_many, through: :medium_tag_joins },
      { to: Tag, type: :has_many, through: :relations, fk: :tag_id, assoc_fk: :related_tag_id },
      { to: Notion, type: :has_many, fk: :tag_id },
      { to: Notion, type: :has_many, fk: :aliased_tag_id }
      # The `belongs_to :term` dependency is deliberately not listed here
      # to prevent a change in one lecture from invalidating all other lectures
      # in the same term (a "mass invalidation" event).
      # The Term -> Lecture dependency is defined in the Term entry, which
      # correctly handles invalidation when a Term itself is updated.
    ],
    Item => [
      { to: Section, type: :belongs_to, fk: :section_id },
      { to: Medium, type: :belongs_to, fk: :medium_id },
      { to: Item, type: :has_many, through: :item_self_joins, fk: :item_id,
        assoc_fk: :related_item_id },
      { to: Medium, type: :has_many, through: :referrals }
    ],
    Notion => [
      { to: Tag, type: :belongs_to, fk: :tag_id },
      { to: Tag, type: :belongs_to, fk: :aliased_tag_id }
    ],
    Quiz => [
      { to: Medium, type: :sti_identity }
    ],
    Remark => [
      { to: Medium, type: :sti_identity }
    ],
    Term => [
      { to: Lecture, type: :has_many, fk: :term_id }
    ]
  }.freeze

  ALL_MODELS = (DEPENDENCY_MAP.keys +
                DEPENDENCY_MAP.values.flatten.filter_map do |d|
                  d[:through]&.to_s&.classify&.constantize
                end).uniq
  FINAL_DEPENDENCY_MAP = DEPENDENCY_MAP.freeze

  # A set of all models that can trigger a cache invalidation.
  WHITELISTED_MODELS = ALL_MODELS.to_set.freeze
  TYPE_TO_CLASS = ALL_MODELS.index_by(&:name).freeze

  class << self
    def run(model)
      # Re-entrancy Guard: Prevent the service from running if it's already
      # active in the current thread. This stops loops caused by our own updates.
      return if Thread.current[:_cache_invalidator_running]

      # Immediately exit if the model is not part of the dependency graph.
      # This prevents running expensive queries for unrelated models like User.
      return unless WHITELISTED_MODELS.include?(model.class.base_class)

      Thread.current[:_cache_invalidator_running] = true
      begin
        # Get all dependent items in a single query.
        buckets = closure_from(model.class.base_class.name, model.id)
        timestamp = Time.current

        # Consolidate STI classes into their base class to prevent redundant updates.
        # For example, merge Question IDs into the Medium bucket.
        buckets.each_key do |klass|
          next if klass.nil? || klass.base_class == klass || !buckets.key?(klass.base_class)

          base_class = klass.base_class
          ids_to_merge = buckets.delete(klass)
          buckets[base_class].concat(ids_to_merge).uniq!
        end

        # Update all items in each bucket
        buckets.each do |klass, ids|
          next if ids.empty?

          # rubocop:disable Rails/SkipsModelValidations
          klass.where(id: ids.uniq).update_all(updated_at: timestamp)
          # rubocop:enable Rails/SkipsModelValidations
        end
      ensure
        # Always clear the flag, even if an error occurs.
        Thread.current[:_cache_invalidator_running] = false
      end
    end

    private

      # Generates the large EDGES_SQL string from the DEPENDENCY_MAP and memoizes it.
      def edges_sql
        @edges_sql ||= FINAL_DEPENDENCY_MAP.flat_map do |src_model, dependencies|
          dependencies.map do |dep|
            generate_sql_for_dependency(src_model, dep)
          end
        end.compact.join("\nUNION ALL\n")
      end

      def generate_sql_for_dependency(src_model, dep)
        src_table = src_model.table_name
        dst_model = dep[:to]

        case dep[:type]
        when :sti_identity
          # Generates a highly efficient edge for STI inheritance.
          # Instead of scanning the entire base table (e.g., media), this
          # creates an edge only for rows of the specific subclass (e.g., Question).
          base_table = src_model.base_class.table_name
          <<~SQL.squish
            SELECT '#{src_model}' AS src_type,
                   #{base_table}.id AS src_id,
                   '#{dst_model}' AS dst_type,
                   #{base_table}.id AS dst_id
            FROM #{base_table}
            WHERE #{base_table}.type = '#{src_model}'
          SQL
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
            # For a has_many :through, we return an array of two SQL fragments.
            # The main `edges_sql` method will join them with UNION ALL.
            join_model = dep[:through].to_s.classify.constantize
            join_table = join_model.table_name
            src_fk_on_join = dep[:fk] || "#{src_model.name.underscore}_id"
            dst_fk_on_join = dep[:assoc_fk] || "#{dst_model.name.underscore}_id"

            [
              # Edge from source to join model
              <<~SQL.squish,
                SELECT '#{src_model}' AS src_type,
                       #{src_fk_on_join} AS src_id,
                       '#{join_model}' AS dst_type,
                       id AS dst_id
                FROM #{join_table}
              SQL
              # Edge from join model to destination
              <<~SQL.squish
                SELECT '#{join_model}' AS src_type,
                       id AS src_id,
                       '#{dst_model}' AS dst_type,
                       #{dst_fk_on_join} AS dst_id
                FROM #{join_table}
              SQL
            ]
          else
            # Corrected logic for :has_many (without :through).
            # This selects from the destination table, which is more efficient.
            dst_table = dst_model.table_name
            <<~SQL.squish
              SELECT '#{src_model}' AS src_type,
                     #{dst_table}.#{dep[:fk]} AS src_id,
                     '#{dst_model}' AS dst_type,
                     #{dst_table}.id AS dst_id
              FROM #{dst_table}
            SQL
          end
        when :polymorphic_has_many
          # Corrected logic for :polymorphic_has_many.
          # This selects from the destination table, which is more efficient.
          dst_table = dst_model.table_name
          <<~SQL.squish
            SELECT '#{src_model}' AS src_type,
                   #{dst_table}.#{dep[:as]}_id AS src_id,
                   '#{dst_model}' AS dst_type,
                   #{dst_table}.id AS dst_id
            FROM #{dst_table}
            WHERE #{dst_table}.#{dep[:as]}_type = '#{src_model}'
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

        # Group the results by class name using a safe whitelist.
        # We reject any groups where the class (the key) could not be resolved,
        # preventing `nil.where` errors for models outside the dependency map.
        # This is crucial for polymorphic relations that might point to an unmapped model.
        rows.group_by { |row| TYPE_TO_CLASS[row["type"]] }
            .reject { |klass, _ids| klass.nil? }
            .transform_values { |value| value.map { |row| row["id"] } }
      end
  end
end
