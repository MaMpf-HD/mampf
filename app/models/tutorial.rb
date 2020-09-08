# Tutorial model
class Tutorial < ApplicationRecord
  belongs_to :tutor, class_name: 'User', foreign_key: 'tutor_id'
  belongs_to :lecture
end
