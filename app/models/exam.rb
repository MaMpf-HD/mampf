class Exam < ApplicationRecord
  belongs_to :lecture

  validates :title, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true

  def destructible?
    non_destructible_reason.nil?
  end

  def non_destructible_reason
    nil
  end

  def registration_title
    return title unless date

    "#{title} (#{I18n.l(date, format: :short)})"
  end
end