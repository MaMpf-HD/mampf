# Teacher class
class Teacher < ApplicationRecord
  has_many :lectures
  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true,
                    format: { with:
                                /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
end
