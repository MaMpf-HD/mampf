class TutorTutorialJoin < ApplicationRecord
  belongs_to :tutorial
  belongs_to :tutor, class_name: "User", inverse_of: :tutor_tutorial_join
end
