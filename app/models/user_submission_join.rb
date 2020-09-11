class UserSubmissionJoin < ApplicationRecord
  belongs_to :user
  belongs_to :submission

  # TODO validatee that there is only one per user and assignment
end
