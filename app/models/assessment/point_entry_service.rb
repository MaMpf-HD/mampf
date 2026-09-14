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
        # State and stamp are decided on what is in the database now, not on
        # what this request loaded: an absence, an exemption or a grade saved
        # in between waits for this write or is seen by it.
        participation.lock!
        refuse_absent_or_exempt!(participation)

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
          # Preserve the original grader and updated_at when points are unchanged;
          # a newer timestamp would falsely report points changed after grading.
          next if tp.persisted? && !tp.points_changed?

          tp.grader = grader
          tp.submission_id = submission&.id
          tp.save!
        end

        participation.recompute_points_total!
        participation.update_status_if_all_scored!(grader: grader)
      end

      participation
    end

    def self.refuse_absent_or_exempt!(participation)
      return unless participation.absent? || participation.exempt?

      status = I18n.t("assessment.grading_exam.status_word.#{participation.status}")
      raise(PointEntryError, I18n.t("assessment.grading_exam.not_scorable", status: status))
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

    private_class_method :validate_points, :refuse_absent_or_exempt!
  end
end
