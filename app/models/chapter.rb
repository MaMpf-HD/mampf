# Chapter class
class Chapter < ApplicationRecord
  belongs_to :lecture
  has_many :sections
  validates :title, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :lecture_id,
                                   message: 'chapter already exists' }
end
