class Subject < ApplicationRecord
	has_many :areas
	has_many :programs

	translates :name
	globalize_accessors locales: I18n.available_locales,
											attributes: translated_attribute_names
end
