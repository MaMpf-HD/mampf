class Area < ApplicationRecord
	belongs_to :subject
	has_many :area_course_joins
	has_many :courses, through: :area_course_joins

	translates :name
end
