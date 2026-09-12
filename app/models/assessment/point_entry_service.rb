module Assessment
  class PointEntryService
    class PointEntryError < StandardError; end

    # task_points maps task IDs to numeric values or strings; nil and empty
    # strings clear points so a blank form field can undo a point entry.
    def self.enter_points(participation,
                          task_points,
                          grader,
                          submission = nil)
      assessment = participation.assessment

      unless assessment.requires_points?
        raise(PointEntryError,
              I18n.t("assessment.task_points.assessment_does_not_require_points",
                     assessment_id: assessment.id))
      end

      valid_task_ids = assessment.tasks.pluck(:id)

      ApplicationRecord.transaction do
        task_points.each do |task_id, points|
          unless valid_task_ids.include?(task_id)
            raise(PointEntryError,
                  I18n.t("assessment.task_points.invalid_task_id", task_id: task_id))
          end

          tp = TaskPoint.find_or_initialize_by(
            assessment_participation_id: participation.id,
            task_id: task_id
          )

          validate_points(points, task_id)

          value = points.presence&.to_f
          tp.points = value
          tp.grader = grader
          tp.submission_id = submission&.id
          tp.save!
        end

        participation.recompute_points_total!
        participation.update_status_if_all_scored!(grader: grader)
      end

      participation
    end

    def self.validate_points(points, task_id)
      return if points.nil?
      return if points.is_a?(String) && points.empty?

      if points.is_a?(String)
        begin
          Float(points)
        rescue ArgumentError
          raise(PointEntryError,
                I18n.t("assessment.task_points.invalid_points_value", task_id: task_id))
        end
      elsif !points.is_a?(Numeric)
        raise(PointEntryError,
              I18n.t("assessment.task_points.invalid_points_value", task_id: task_id))
      end
    end

    private_class_method :validate_points
  end
end
