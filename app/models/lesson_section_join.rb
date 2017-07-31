# LessonSectionJoin class
# JoinTable for lesson <-> section many-to-many-relation
class LessonSectionJoin < ApplicationRecord
  belongs_to :lesson
  belongs_to :section
end
