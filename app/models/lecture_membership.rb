# Represents a user's official membership in a lecture's roster, distinct from
# casual subscriptions, and tracks the source campaign for automated management.
# When someone leaves, the row stays and is marked as excluded, so the staff
# can see who left and take them back.
class LectureMembership < ApplicationRecord
  belongs_to :user
  belongs_to :lecture
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true
  belongs_to :excluded_by, class_name: "User", optional: true

  scope :active, -> { where(excluded_at: nil) }
  scope :excluded, -> { where.not(excluded_at: nil) }

  after_commit :sync_student_performance, if: :joined_roster?
  after_commit :delete_performance_record, if: :left_roster?

  def excluded?
    excluded_at.present?
  end

  def left_by_self?
    excluded_by_id == user_id
  end

  def exclude!(by: nil)
    update!(excluded_at: Time.current, excluded_by: by)
  end

  private

    def sync_student_performance
      lecture.sync_student_performance_for_members!([user_id])
    end

    def joined_roster?
      return false if destroyed?

      previously_new_record? || (saved_change_to_excluded_at? && !excluded?)
    end

    def left_roster?
      destroyed? || (saved_change_to_excluded_at? && excluded?)
    end

    # Deletes the performance record of someone who leaves; it is rebuilt from
    # their points when they come back. Their exam admission is kept.
    def delete_performance_record
      StudentPerformance::Record
        .where(lecture_id: lecture_id, user_id: user_id)
        .delete_all
    end
end
