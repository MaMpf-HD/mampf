module Assessment
  class PointEntryService
    # must ensure participation and task valid before calling this method
    # task_points is a Hash of task_id => points, points potentially nil and string
    def self.enter_points(participation,
                          task_points,
                          grader,
                          submission = nil)
      assessment = participation.assessment

      # check requires_points
      unless assessment.requires_points?
        raise(ArgumentError,
              "Assessment #{assessment.id} does not accept points")
      end

      # validate task ids belong to the assessment
      valid_task_ids = assessment.tasks.pluck(:id)

      ApplicationRecord.transaction do
        task_points.each do |task_id, points|
          unless valid_task_ids.include?(task_id)
            raise(ArgumentError,
                  "Invalid task #{task_id}")
          end

          tp = TaskPoint.find_or_initialize_by(
            assessment_participation_id: participation.id,
            task_id: task_id
          )

          # validate points is a number if present, allow nil for unscoring
          validate_points(points, task_id)

          value = points.presence&.to_f
          tp.points = value
          tp.grader = grader
          tp.submission_id = submission&.id
          tp.save!
        end

        participation.recompute_points_total!
        participation.update_status_if_all_scored!
      end

      participation
    end

    private_class_method :validate_points

    def self.validate_points(points, task_id)
      return if points.nil?
      return if points.is_a?(String) && points.empty?

      if points.is_a?(String)
        begin
          Float(points)
        rescue ArgumentError
          raise(ArgumentError, "Invalid points value for task #{task_id}")
        end
      elsif !points.is_a?(Numeric)
        raise(ArgumentError, "Invalid points value for task #{task_id}")
      end
    end
  end
end
