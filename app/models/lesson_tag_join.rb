# LessonTagJoin class
# JoinTable for lesson <-> tag many-to-many-relation
class LessonTagJoin < ApplicationRecord
  belongs_to :lesson
  belongs_to :tag
end
