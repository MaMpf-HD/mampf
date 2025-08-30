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
      { to: Tag, type: :has_many, through: :course_tag_joins }
    ],
    Lecture => [
      { to: Course, type: :belongs_to, fk: :course_id },
      { to: Chapter, type: :has_many, fk: :lecture_id },
      { to: Lesson, type: :has_many, fk: :lecture_id },
      { to: Talk, type: :has_many, fk: :lecture_id },
      { to: Medium, type: :polymorphic_has_many, as: :teachable },
      { to: Assignment, type: :has_many, fk: :lecture_id }
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
        assoc_fk: :linked_medium_id }
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
    ]
  }.freeze

  # Dynamically add join table dependencies
  #
  # A change to a join model (e.g., CourseTagJoin) must invalidate both of its
  # parent models (Course and Tag). Manually adding every join model to the
  # DEPENDENCY_MAP is repetitive and error-prone. A developer might add a new
  # `has_many :through` association but forget to update this service.
  #
  # This code automates the process. It treats the `has_many :through`
  # definitions in the DEPENDENCY_MAP as the single source of truth. It iterates
  # through them and programmatically generates the correct dependency entries
  # for the underlying join models (e.g., CourseTagJoin => [belongs_to :course, ...]).
  generated_join_deps = {}
  DEPENDENCY_MAP.each do |src_model, dependencies|
    dependencies.each do |dep|
      next unless dep[:type] == :has_many && dep[:through]

      join_table_name = dep[:through].to_s
      join_model = join_table_name.classify.constantize
      dst_model = dep[:to]

      # Define the foreign keys for the join model's belongs_to associations
      src_fk = dep[:fk] || "#{src_model.name.underscore}_id"
      dst_fk = dep[:assoc_fk] || "#{dst_model.name.underscore}_id"

      # Create the dependency entries for the join model
      generated_join_deps[join_model] = [
        { to: src_model, type: :belongs_to, fk: src_fk },
        { to: dst_model, type: :belongs_to, fk: dst_fk }
      ]
    end
  end

  # Create the final, complete, and frozen map by merging the initial map
  # with the auto-generated join dependencies. This is now the single source
  # of truth for all subsequent logic.
  FINAL_DEPENDENCY_MAP = DEPENDENCY_MAP.merge(generated_join_deps).freeze

  # A set of all models that can trigger a cache invalidation.
  # This is derived directly from the FINAL_DEPENDENCY_MAP for efficient lookups.
  WHITELISTED_MODELS = FINAL_DEPENDENCY_MAP.keys.to_set.freeze
  TYPE_TO_CLASS = FINAL_DEPENDENCY_MAP.keys.index_by(&:name).freeze

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
