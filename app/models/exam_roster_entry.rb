class ExamRosterEntry < ApplicationRecord
  belongs_to :exam
  belongs_to :user
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  scope :active, -> { where(excluded_at: nil) }
  scope :excluded, -> { where.not(excluded_at: nil) }

  validates :user_id, uniqueness: { scope: :exam_id }

  def excluded?
    excluded_at.present?
  end

  def exclusion_reason_label
    I18n.t("assessment.registration_tab.removed_from_roster_reason")
  end
end
