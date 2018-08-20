# Teacher class
class Teacher < ApplicationRecord
  has_many :lectures
  has_one :user
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

  def self.without_accounts?
    Teacher.all.to_a.any? { |t| t.user.nil? }
  end

  def self.without_accounts
    Teacher.all.to_a.select { |t| t.user.nil? }
  end

  private

  def homepage_present?
    homepage.present?
  end
end
