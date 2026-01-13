class Cohort < ApplicationRecord
  include Registration::Registerable

  belongs_to :context, polymorphic: true

  enum :purpose, {
    general: 0,
    enrollment: 1,
    planning: 2
  }

  attr_readonly :propagate_to_lecture

  validates :title, presence: true
  validates :purpose, presence: true
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

  def registration_title
    title
  end
end
