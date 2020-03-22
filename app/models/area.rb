class Area < ApplicationRecord
	belongs_to :subject
	has_many :area_course_joins
	has_many :courses, through: :area_course_joins

	translates :name
	globalize_accessors locales: I18n.available_locales,
											attributes: translated_attribute_names
end
