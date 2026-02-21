# Provides the association between Exams and Users for exam participation.
class ExamRoster < ApplicationRecord
  belongs_to :exam
  belongs_to :user
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  validates :user_id, uniqueness: { scope: :exam_id }
end
