class TutorTutorialJoin < ApplicationRecord
  belongs_to :tutorial
  belongs_to :tutor, class_name: "User" # rubocop:todo Rails/InverseOf
end
