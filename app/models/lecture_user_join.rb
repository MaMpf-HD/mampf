# LectureUserJoin class
# JoinTable for lecture <-> user many-to-many-relation
# describes which user have subscribed a lecture
class LectureUserJoin < ApplicationRecord
  belongs_to :lecture
  belongs_to :user
end
