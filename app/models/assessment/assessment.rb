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
    has_one :grade_scheme, -> { where(active: true) },
            class_name: "Assessment::GradeScheme",
            inverse_of: :assessment

    accepts_nested_attributes_for :assessable

    delegate :title, to: :assessable

    def results_published?
      results_published_at.present?
    end

    def effective_total_points
      total_points || tasks.sum(:max_points)
    end

    validate :lecture_matches_assessable

    def seed_participations_from!(user_ids:, tutorial_mapping: {})
      existing = assessment_participations.pluck(:user_id).to_set
      new_user_ids = user_ids.reject { |uid| existing.include?(uid) }

      return if new_user_ids.empty?

      participations_data = new_user_ids.map do |user_id|
        {
          assessment_id: id,
          user_id: user_id,
          tutorial_id: tutorial_mapping[user_id],
          # We can't use :pending directly because insert_all doesn't apply the
          # enum mapping
          status: Participation.statuses[:pending],
          points_total: nil,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # rubocop:disable Rails/SkipsModelValidations
      Participation.insert_all(
        participations_data,
        unique_by: [:assessment_id, :user_id]
      )
      # rubocop:enable Rails/SkipsModelValidations
    end

    private

      def lecture_matches_assessable
        return unless lecture_id.present? && assessable&.lecture_id.present?

        return unless assessable.lecture_id != lecture_id

        errors.add(:lecture_id, :must_match_assessable_lecture)
      end
  end
end
