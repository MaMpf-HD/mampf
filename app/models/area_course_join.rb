class AreaCourseJoin < ApplicationRecord
  belongs_to :area
  belongs_to :course

  enum level: { basic: 0, advanced: 1, expert: 3 }
end
