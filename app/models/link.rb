# Link class
# JoinTable for medium<->medium many-to-many-relation
# describes which media are related to a given medium
class Link < ApplicationRecord
  belongs_to :medium
  belongs_to :linked_medium, class_name: 'Medium'

  # we do not want duplicate entries
  validates :linked_medium, uniqueness: { scope: :medium }

  # after saving, we symmetrize the relation
  after_save :create_inverse, unless: :inverse?
  # we do not want a medium to be in relation to itself
  after_save :destroy, if: :self_inverse?
  # after a link is destroyed, destroy the link in the other direction as well
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
