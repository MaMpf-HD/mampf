# Records that the staff of a lecture made somebody a tutor by the address of
# their account, as a redeemed tutor voucher does: they can then be put on a
# group, whether the lecture has one yet or not.
class TutorAppointment < ApplicationRecord
  belongs_to :lecture
  belongs_to :user

  validates :user_id, uniqueness: { scope: :lecture_id }
end
