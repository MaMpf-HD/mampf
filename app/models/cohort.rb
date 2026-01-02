class Cohort < ApplicationRecord
  include Registration::Registerable

  belongs_to :context, polymorphic: true

  validates :title, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def allocated_user_ids
    raise(NotImplementedError, "Cohort must implement #allocated_user_ids")
  end

  def materialize_allocation!(user_ids:, campaign:)
    raise(NotImplementedError, "Cohort must implement #materialize_allocation!")
  end

  def lecture
    context if context.is_a?(Lecture)
  end
end
