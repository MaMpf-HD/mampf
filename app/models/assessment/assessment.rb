module Assessment
  # Represents a specific instance of a user participating in an assessment.
  # It tracks the user's status, points, and grading information for that assessment.
  class Assessment < ApplicationRecord
    belongs_to :assessable, polymorphic: true
    belongs_to :lecture

    delegate :grading_open?, to: :assessable, allow_nil: true

    has_many :tasks, dependent: :destroy, class_name: "Assessment::Task",
                     inverse_of: :assessment
    has_many :assessment_participations, dependent: :destroy,
                                         class_name: "Assessment::Participation",
                                         inverse_of: :assessment
    has_many :task_points, through: :assessment_participations,
                           class_name: "Assessment::TaskPoint"

    accepts_nested_attributes_for :assessable

    delegate :title, to: :assessable

    def short_title
      parts = title.split(" ", 2)
      parts.length > 1 ? parts.last.presence || title.truncate(5) : title.truncate(5)
    end

    def results_published?
      results_published_at.present?
    end

    def effective_total_points
      total_points || tasks.sum(:max_points)
    end

    validate :lecture_matches_assessable
    validate :requires_submission_locked_after_deadline,
             if: -> { requires_submission_changed? }

    after_commit :recompute_all_performance_records,
                 on: [:destroy, :update],
                 if: :should_recompute_performance_records?

    def seed_participations_from!(user_ids:, tutorial_mapping: {},
                                  recompute: true)
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

      recompute_all_performance_records if recompute
    end

    private

      def lecture_matches_assessable
        return unless lecture_id.present? && assessable&.lecture_id.present?

        return unless assessable.lecture_id != lecture_id

        errors.add(:lecture_id, :must_match_assessable_lecture)
      end

      def requires_submission_locked_after_deadline
        return unless assessable.is_a?(Assignment) && assessable.past_deadline?

        errors.add(:requires_submission, :locked_after_deadline)
      end

      def should_recompute_performance_records?
        return false unless assessable_type == "Assignment"

        destroyed? || saved_change_to_total_points?
      end

      def recompute_all_performance_records
        return unless Flipper.enabled?(:assessment_grading)

        StudentPerformance::ComputationService
          .new(lecture: lecture)
          .compute_and_upsert_all_records!
      end
  end
end
