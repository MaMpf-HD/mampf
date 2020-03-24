class Program < ApplicationRecord
	belongs_to :subject
	has_many :divisions, dependent: :destroy

	translates :name
	globalize_accessors locales: I18n.available_locales,
											attributes: translated_attribute_names

	def name_with_subject
		"#{subject.name}:#{name}"
	end

	def courses
		divisions.map(&:courses).flatten
	end
end
