class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins
  has_many :users, through: :user_submission_joins
end
