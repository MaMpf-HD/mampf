# Represents a user's official membership in a lecture's roster, distinct from
# casual subscriptions, and tracks the source campaign for automated management.
class LectureMembership < ApplicationRecord
  belongs_to :user
  belongs_to :lecture
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  after_commit :recompute_performance_record, on: :create
  after_commit :delete_performance_record, on: :destroy

  private

    def recompute_performance_record
      return unless Flipper.enabled?(:student_performance)

      StudentPerformance::ComputationService
        .new(lecture: lecture)
        .compute_and_upsert_record_for(user)
    end

    def delete_performance_record
      return unless Flipper.enabled?(:student_performance)

      StudentPerformance::Record
        .where(lecture_id: lecture_id, user_id: user_id)
        .delete_all
    end
end
