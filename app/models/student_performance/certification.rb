module StudentPerformance
  class Certification < ApplicationRecord
    enum :status, { pending: 0, passed: 1, failed: 2 }
    enum :source, { computed: 0, manual: 1 }

    belongs_to :lecture
    belongs_to :user
    belongs_to :certified_by, class_name: "User", optional: true
    belongs_to :rule, class_name: "StudentPerformance::Rule", optional: true

    validates :lecture_id, uniqueness: { scope: :user_id }
    validates :certified_by, presence: true, unless: :pending?
    validates :certified_at, presence: true, unless: :pending?

    scope :stale, lambda {
      joins(
        "INNER JOIN student_performance_records ON " \
        "student_performance_records.lecture_id = " \
        "student_performance_certifications.lecture_id " \
        "AND student_performance_records.user_id = " \
        "student_performance_certifications.user_id"
      ).where(
        "student_performance_records.computed_at > " \
        "student_performance_certifications.certified_at"
      )
    }

    def self.passed?(lecture:, user:)
      find_by(lecture: lecture, user: user)&.passed? || false
    end
  end
end
