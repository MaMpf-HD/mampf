class Tag < ApplicationRecord
  alias_attribute :disabled_lectures, :lectures
  has_many :contents
  has_many :courses, through: :contents
  has_many :disabled_contents
  has_many :lectures, through: :disabled_contents
end
