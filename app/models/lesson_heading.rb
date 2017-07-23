class LessonHeading < ApplicationRecord
  belongs_to :lesson
  belongs_to :section
end
