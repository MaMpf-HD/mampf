module Assessment
  class PointEntryService
    # must ensure participation and task valid before calling this method
    def self.enter_points(participation,
                     task_points, # Hash of task_id => points, points potentially nil and string
                     grader)
      assessment = participation.assessment
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

          tp.points = points&.to_f
          tp.grader = grader
          tp.save!
        end

        participation.recompute_points_total!
      end

      participation
    end
  end
end
