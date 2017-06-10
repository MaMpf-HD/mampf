class Lecture < ApplicationRecord
  alias_attribute :disabled_tags, :tags
  belongs_to :course
  belongs_to :teacher
  has_many :disabled_contents
  has_many :tags, through: :disabled_contents
  has_many :lessons
end
