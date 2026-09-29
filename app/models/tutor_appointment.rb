# Records that the staff of a lecture made somebody a tutor by the address of
# their account, without a voucher. They can then be put on a group.
class TutorAppointment < ApplicationRecord
  belongs_to :lecture
  belongs_to :user

  validates :user_id, uniqueness: { scope: :lecture_id }
end
