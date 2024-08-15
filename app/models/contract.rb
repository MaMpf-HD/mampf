class Contract < ApplicationRecord
  belongs_to :user
  belongs_to :lecture

  scope :tutors, -> { where(role: ROLE_HASH[:tutor]) }
  scope :editors, -> { where(role: ROLE_HASH[:editor]) }

  ROLE_HASH = { tutor: 0, editor: 1 }.freeze

  enum role: ROLE_HASH
end
