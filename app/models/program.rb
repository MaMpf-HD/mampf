class Program < ApplicationRecord
	belongs_to :subject
	has_many :program_course_joins
	has_many :courses, through: :program_course_joins

	translates :name
end
