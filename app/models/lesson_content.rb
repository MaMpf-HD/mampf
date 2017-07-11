# LessonContent class
# JoinTable for lesson <-> tag many-to-many-relation
class LessonContent < ApplicationRecord
  belongs_to :lesson
  belongs_to :tag
end
