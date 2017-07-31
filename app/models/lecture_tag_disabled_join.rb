# LectureTagDisabledJoin class
# JoinTable for lecture <-> (disabled) tag many-to-many-relation
class LectureTagDisabledJoin < ApplicationRecord
  belongs_to :lecture
  belongs_to :tag
end
