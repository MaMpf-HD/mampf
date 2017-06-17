# Teacher class
class Teacher < ApplicationRecord
  has_many :lectures
  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
end
