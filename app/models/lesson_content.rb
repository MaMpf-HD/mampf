class LessonContent < ApplicationRecord
  belongs_to :lesson
  belongs_to :tag
end
