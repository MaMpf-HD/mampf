module Assessment
  class Assessment < ApplicationRecord
    belongs_to :assessable, polymorphic: true
    belongs_to :lecture

    has_many :tasks, dependent: :destroy, class_name: "Assessment::Task",
                     inverse_of: :assessment
    has_many :assessment_participations, dependent: :destroy,
                                         class_name: "Assessment::Participation",
                                         inverse_of: :assessment
    has_many :task_points, through: :assessment_participations,
                           class_name: "Assessment::TaskPoint"

    enum :status, { draft: 0, open: 1, closed: 2, graded: 3, archived: 4 }

    delegate :title, to: :assessable

    validate :lecture_matches_assessable

    private

      def lecture_matches_assessable
        return unless lecture_id.present? && assessable&.lecture_id.present?

        return unless assessable.lecture_id != lecture_id

        errors.add(:lecture_id, "must match assessable's lecture")
      end
  end
end
