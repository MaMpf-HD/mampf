class CacheInvalidatorService
  # The dependency graph. Maps a model class to a lambda that returns
  # an array of dependent objects. We will populate this incrementally.
  DEPENDENCY_MAP = {
    Course => ->(course) { course.lectures + course.media + course.tags },
    Lecture => lambda { |lecture|
      [lecture.course] + lecture.chapters + lecture.lessons + lecture.talks + lecture.media
    },
    Chapter => ->(chapter) { [chapter.lecture] + chapter.sections },
    Section => ->(section) { [section.chapter] + section.lessons + section.tags },
    Lesson => ->(lesson) { [lesson.lecture] + lesson.sections + lesson.media + lesson.tags },
    Talk => ->(talk) { [talk.lecture] + talk.media + talk.tags },
    Medium => ->(medium) { [medium.teachable] + medium.tags },
    Tag => lambda { |tag|
      tag.courses + tag.sections + tag.lessons + tag.talks + tag.media + tag.related_tags
    }
  }.freeze

  FAN_OUT_LOG_THRESHOLD = 50

  class << self
    # The main public method.
    # It orchestrates the gathering of all dependencies and then invalidates them
    # in a single, efficient batch.
    def run(model, event_name: "unknown")
      # 1. Gather all unique dependents recursively.
      all_dependents = gather_all_dependents(model, event_name: event_name)
      return if all_dependents.empty?

      # 2. Invalidate the collected dependents in batches.
      timestamp = Time.current # Keep full microsecond precision
      dependents_by_class = all_dependents.group_by(&:class)

      dependents_by_class.each do |klass, records|
        if records.size > FAN_OUT_LOG_THRESHOLD
          Rails.logger.warn("[CacheInvalidator] Large fan-out from #{model.class.name}##{model.id} " \
                            "(#{event_name}): Invalidating #{records.size} #{klass.name} records.")
        end
        # We intentionally skip callbacks and validations for performance and to prevent
        # an infinite loop of after_commit hooks.
        # rubocop:disable Rails/SkipsModelValidations
        klass.where(id: records.map!(&:id)).update_all(updated_at: timestamp)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    private

      # Helper to find a dependency rule, walking up the inheritance chain for STI.
      def dependents_proc_for(klass)
        k = klass
        while k && k <= ActiveRecord::Base
          proc = DEPENDENCY_MAP[k]
          return proc if proc

          k = k.superclass
        end
        nil
      end

      # This private method walks the dependency graph and returns a Set of all
      # unique objects that need to be invalidated.
      def gather_all_dependents(initial_model, event_name:, visited: Set.new)
        # Use a queue for graph traversal.
        queue = [initial_model]
        all_deps = Set.new

        while (model = queue.shift)
          model_key = [model.class.name, model.id]
          next if visited.include?(model_key)

          visited.add(model_key)

          dependents_proc = dependents_proc_for(model.class)
          next unless dependents_proc

          begin
            dependents = Array(dependents_proc.call(model)).compact.uniq
            unless dependents.empty?
              all_deps.merge(dependents)
              queue.concat(dependents)
            end
          rescue StandardError => e
            Rails.logger.error("[CacheInvalidator] Failed resolving dependents for #{model.class.name}##{model.id} (#{event_name}): #{e.full_message}")
            # Continue with the next item in the queue, halting this branch.
          end
        end

        all_deps
      end
  end
end
