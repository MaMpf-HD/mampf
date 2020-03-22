class Division < ApplicationRecord
  belongs_to :program
  has_many :division_course_joins
  has_many :courses, through: :division_course_joins

	translates :name

	globalize_accessors locales: I18n.available_locales,
											attributes: translated_attribute_names

	def name_with_program
		"#{program.subject.name}:#{program.name}:#{name}"
	end
end
