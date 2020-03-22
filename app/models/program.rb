class Program < ApplicationRecord
	belongs_to :subject
	has_many :program_course_joins
	has_many :courses, through: :program_course_joins

	translates :name
	globalize_accessors locales: I18n.available_locales,
											attributes: translated_attribute_names

	def name_with_subject
		"#{subject.name}:#{name}"
	end
end
