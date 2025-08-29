class CacheInvalidatorService
  # Each resolver now takes an array of IDs and returns a hash mapping a
  # dependent class to an array of its IDs.
  # Queries are optimized to use join tables directly and fetch IDs in bulk.
  RESOLVERS = {
    Course => lambda { |ids|
      {
        Lecture => Lecture.where(course_id: ids).reorder(nil).pluck(:id),
        Medium => Medium.where(teachable_type: "Course", teachable_id: ids)
                        .reorder(nil).pluck(:id),
        Tag => CourseTagJoin.where(course_id: ids).reorder(nil).pluck(:tag_id)
      }
    },
    Lecture => lambda { |ids|
      {
        Course => Lecture.where(id: ids).reorder(nil).pluck(:course_id).compact,
        Chapter => Chapter.where(lecture_id: ids).reorder(nil).pluck(:id),
        Lesson => Lesson.where(lecture_id: ids).reorder(nil).pluck(:id),
        Talk => Talk.where(lecture_id: ids).reorder(nil).pluck(:id),
        Medium => Medium.where(teachable_type: "Lecture", teachable_id: ids)
                        .reorder(nil).pluck(:id)
      }
    },
    Chapter => lambda { |ids|
      {
        Lecture => Chapter.where(id: ids).reorder(nil).pluck(:lecture_id).compact,
        Section => Section.where(chapter_id: ids).reorder(nil).pluck(:id)
      }
    },
    Section => lambda { |ids|
      {
        Chapter => Section.where(id: ids).reorder(nil).pluck(:chapter_id).compact,
        Lesson => LessonSectionJoin.where(section_id: ids).reorder(nil).pluck(:lesson_id),
        Tag => SectionTagJoin.where(section_id: ids).reorder(nil).pluck(:tag_id)
      }
    },
    Lesson => lambda { |ids|
      {
        Lecture => Lesson.where(id: ids).reorder(nil).pluck(:lecture_id).compact,
        Section => LessonSectionJoin.where(lesson_id: ids).reorder(nil).pluck(:section_id),
        Medium => Medium.where(teachable_type: "Lesson", teachable_id: ids)
                        .reorder(nil).pluck(:id),
        Tag => LessonTagJoin.where(lesson_id: ids).reorder(nil).pluck(:tag_id)
      }
    },
    Talk => lambda { |ids|
      {
        Lecture => Talk.where(id: ids).reorder(nil).pluck(:lecture_id).compact,
        Medium => Medium.where(teachable_type: "Talk", teachable_id: ids)
                        .reorder(nil).pluck(:id),
        Tag => TalkTagJoin.where(talk_id: ids).reorder(nil).pluck(:tag_id)
      }
    },
    Medium => lambda { |ids|
      # Group teachables by their class
      teachables = Medium.where(id: ids).reorder(nil)
                         .pluck(:teachable_type, :teachable_id)
      deps = teachables.group_by(&:first)
                       .transform_values { |v| v.map(&:second) }
                       .transform_keys(&:constantize)

      # Get associated tags
      deps[Tag] = MediumTagJoin.where(medium_id: ids).reorder(nil).pluck(:tag_id)
      deps
    },
    Tag => lambda { |ids|
      {
        Course => CourseTagJoin.where(tag_id: ids).reorder(nil).pluck(:course_id),
        Section => SectionTagJoin.where(tag_id: ids).reorder(nil).pluck(:section_id),
        Lesson => LessonTagJoin.where(tag_id: ids).reorder(nil).pluck(:lesson_id),
        Talk => TalkTagJoin.where(tag_id: ids).reorder(nil).pluck(:talk_id),
        Medium => MediumTagJoin.where(tag_id: ids).reorder(nil).pluck(:medium_id),
        # NOTE: `relations` is the join table for a self-referential association
        Tag => Relation.where(tag_id: ids).reorder(nil).pluck(:related_tag_id)
      }
    }
  }.freeze

  FAN_OUT_LOG_THRESHOLD = 50
  BATCH_SIZE = 1000

  class << self
    def run(model, event_name: "unknown")
      # visited stores all nodes seen during traversal: { Klass => Set[id] }
      visited = Hash.new { |h, k| h[k] = Set.new }
      # frontier stores nodes to be processed in the current iteration
      frontier = Hash.new { |h, k| h[k] = Set.new }
      frontier[model.class] << model.id

      loop do
        # next_frontier will collect nodes for the *next* iteration
        next_frontier = Hash.new { |h, k| h[k] = Set.new }

        frontier.each do |klass, ids_set|
          # From the current frontier, select only the IDs we haven't processed yet
          new_ids = ids_set.to_a - visited[klass].to_a
          next if new_ids.empty?

          # Add these new IDs to the global visited set
          visited[klass].merge(new_ids)

          resolver = resolver_for(klass)
          next unless resolver

          # Process in batches to keep `IN (...)` clauses of a reasonable size
          new_ids.each_slice(BATCH_SIZE) do |slice|
            # buckets is a hash like { Klass => [ids] }
            buckets = resolver.call(slice)
            buckets.each do |dep_klass, dep_ids|
              # Add newly found dependencies to the next frontier,
              # but only if they haven't been visited at all yet.
              unseen_deps = dep_ids.compact.uniq - visited[dep_klass].to_a
              next_frontier[dep_klass].merge(unseen_deps)
            end
          end
        end

        # If the next frontier is empty, we're done traversing
        break if next_frontier.values.all?(&:empty?)

        # The next frontier becomes the current frontier for the next iteration
        frontier = next_frontier
      end

      # Batch invalidate all collected IDs for each class with a single timestamp
      timestamp = Time.current
      visited.each do |klass, ids|
        next if ids.empty?

        # rubocop:disable Rails/SkipsModelValidations
        klass.where(id: ids.to_a).update_all(updated_at: timestamp)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    private

      # Helper to find a resolver, walking up the inheritance chain for STI.
      def resolver_for(klass)
        k = klass
        while k && k <= ActiveRecord::Base
          return RESOLVERS[k] if RESOLVERS.key?(k)

          k = k.superclass
        end
        nil
      end
  end
end
