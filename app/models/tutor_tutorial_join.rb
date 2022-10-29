class TutorTutorialJoin < ApplicationRecord
  belongs_to :tutorial
  belongs_to :tutor, class_name: 'User', foreign_key: 'tutor_id'
end
