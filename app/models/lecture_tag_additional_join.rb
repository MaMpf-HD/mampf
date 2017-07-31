# LectureTagAdditionalJoin class
# JoinTable for lecture <-> (additional)tag many-to-many-relation
class LectureTagAdditionalJoin < ApplicationRecord
  belongs_to :lecture
  belongs_to :tag
end
