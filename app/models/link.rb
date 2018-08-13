# Link class
# JoinTable for medium<->medium many-to-many-relation
class Link < ApplicationRecord
  belongs_to :medium
  belongs_to :linked_medium, class_name: 'Medium'
  validates :linked_medium, uniqueness: { scope: :medium,
                                          message: 'link already exists' }
  after_save :create_inverse, unless: :inverse?
  after_save :destroy, if: :self_inverse?
  after_destroy :destroy_inverses, if: :inverse?

  private

  def self_inverse?
    medium_id == linked_medium_id
  end

  def create_inverse
    self.class.create(inverse_link_options)
  end

  def destroy_inverses
    inverses.destroy_all
  end

  def inverse?
    self.class.exists?(inverse_link_options) || self_inverse?
  end

  def inverses
    self.class.where(inverse_link_options)
  end

  def inverse_link_options
    { linked_medium_id: medium_id, medium_id: linked_medium_id }
  end
end
