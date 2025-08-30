# Relation class
# Join table for tag<->tag many-to-many-relation
class Relation < ApplicationRecord
  belongs_to :tag
  belongs_to :related_tag, class_name: "Tag"

  validates :related_tag, uniqueness: { scope: :tag }
  after_destroy :destroy_inverses, if: :inverse?
  after_save :create_inverse, unless: :inverse?
  after_save :destroy, if: :self_inverse?

  private

    def create_inverse
      self.class.create(inverse_relation_options)
    end

    def destroy_inverses
      inverses.destroy_all
    end

    def self_inverse?
      tag_id == related_tag_id
    end

    def inverse?
      self.class.exists?(inverse_relation_options) || self_inverse?
    end

    def inverses
      self.class.where(inverse_relation_options)
    end

    def inverse_relation_options
      { related_tag_id: tag_id, tag_id: related_tag_id }
    end
end
