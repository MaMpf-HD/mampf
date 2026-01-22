module Assessment
  class Task < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment",
                            inverse_of: :tasks
    has_many :task_points, dependent: :destroy,
                           class_name: "Assessment::TaskPoint", inverse_of: :task

    validates :title, presence: true
    validates :max_points, numericality: { greater_than_or_equal_to: 0 }
    validate :assessment_requires_points

    acts_as_list scope: :assessment

    private

      def assessment_requires_points
        return if assessment&.requires_points

        errors.add(:base, :requires_points_true)
      end
  end
end
