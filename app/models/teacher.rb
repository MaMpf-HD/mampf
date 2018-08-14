# Teacher class
class Teacher < ApplicationRecord
  has_many :lectures
  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true,
                    format: { with:
                                /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }

  validates :homepage, http_url: true, if: :homepage_present?

  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  private

  def homepage_present?
    homepage.present?
  end
end
