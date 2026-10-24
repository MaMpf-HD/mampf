# Represents a user's official membership in a lecture's roster, distinct from
# casual subscriptions, and tracks the source campaign for automated management.
# Leaving the roster keeps the row as an exclusion, so the lecture's staff can
# still find who has left and take them back.
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

    # The record is worked out from the points, which stay, and is built again
    # on return. The exam admission is a decision and stays too: it counts
    # again the moment the person is back, while the eligibility pages leave it
    # out meanwhile (see Lecture#current_certifications).
    def delete_performance_record
      StudentPerformance::Record
        .where(lecture_id: lecture_id, user_id: user_id)
        .delete_all
    end
end
