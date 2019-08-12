class Vote < ApplicationRecord
  belongs_to :clicker

  validate :clicker_open
  validate :value_in_range

  private

  def clicker_open
    return true if clicker.open?
    errors.add(:clicker, :clicker_closed)
  end

  def value_in_range
    return true if value.in?(1..clicker.alternatives)
    errors.add(:value, :out_of_range)
  end
end
