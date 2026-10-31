class ExamRosterEntry < ApplicationRecord
  belongs_to :exam
  belongs_to :user
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  scope :active, -> { where(excluded_at: nil) }
  scope :excluded, -> { where.not(excluded_at: nil) }

  validates :user_id, uniqueness: { scope: :exam_id }

  # Returns { user_id => [exam title, ...] } for the lecture's exam lists the
  # given people are on, for the removal confirmations.
  def self.exam_titles_by_user(lecture, user_ids)
    active.joins(:exam).where(exams: { lecture_id: lecture.id }, user_id: user_ids)
          .pluck(:user_id, "exams.title")
          .group_by(&:first).transform_values { |rows| rows.map(&:last) }
  end

  def excluded?
    excluded_at.present?
  end

  def exclusion_reason_label
    I18n.t("assessment.registration_tab.removed_from_roster_reason")
  end
end
