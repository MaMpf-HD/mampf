class Subject < ApplicationRecord
	has_many :areas
	has_many :programs

	translates :name
end
