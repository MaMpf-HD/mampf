module Assessment
  class Task < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment",
                            inverse_of: :tasks
    has_many :task_points, dependent: :destroy,
                           class_name: "Assessment::TaskPoint", inverse_of: :task

    validates :max_points, numericality: { greater_than_or_equal_to: 0 }
    validate :assessment_requires_points

    before_destroy :check_no_points_entered, prepend: true

    acts_as_list scope: :assessment

    def points_entered?
      task_points.where.not(points: nil).exists?
    end

    private

      def assessment_requires_points
        return if assessment&.requires_points

        errors.add(:base, :requires_points_true)
      end

      def check_no_points_entered
        throw(:abort) if points_entered?
      end
  end
end
