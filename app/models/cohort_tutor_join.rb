# Makes somebody a tutor of a cohort: they see who is in it and can write to
# them. A cohort usually needs no tutor; nothing in it is marked.
class CohortTutorJoin < ApplicationRecord
  belongs_to :cohort
  belongs_to :tutor, class_name: "User"

  validates :tutor_id, uniqueness: { scope: :cohort_id }
end
