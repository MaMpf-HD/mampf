class Exam < ApplicationRecord
  belongs_to :lecture
  has_many :all_exam_roster_entries,
           class_name: "ExamRosterEntry",
           dependent: :destroy,
           inverse_of: :exam
  has_many :exam_roster_entries,
           -> { active },
           class_name: "ExamRosterEntry",
           inverse_of: :exam
  has_many :excluded_exam_roster_entries,
           -> { excluded },
           class_name: "ExamRosterEntry",
           inverse_of: :exam
  has_many :users, through: :exam_roster_entries

  validates :title, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true

  def destructible?
    non_destructible_reason.nil?
  end

  def non_destructible_reason
    return :roster_not_empty if exam_roster_entries.exists?

    nil
  end

  def registration_title
    return title unless date

    "#{title} (#{I18n.l(date, format: :short)})"
  end

  def roster_entries
    exam_roster_entries
  end

  def roster_association_name
    :exam_roster_entries
  end

  def roster_user_id_column
    :user_id
  end

  def add_user_to_roster!(user, source_campaign = nil)
    roster_entry = all_exam_roster_entries.find_or_initialize_by(user: user)
    roster_entry.source_campaign ||= source_campaign
    roster_entry.excluded_at = nil
    roster_entry.save!
    roster_entry
  end

  def remove_user_from_roster!(user)
    roster_entry = all_exam_roster_entries.find_by(user: user)
    roster_entry&.destroy!
  end
end
