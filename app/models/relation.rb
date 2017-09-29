# Relation class
# Join table for tag<->tag many-to-many-relation
class Relation < ApplicationRecord
  belongs_to :tag
  belongs_to :related_tag, class_name: 'Tag'

  validates :related_tag, uniqueness: { scope: :tag,
                                        message: 'relation already exists' }
  after_create :create_inverse, unless: :inverse?
  after_create :destroy_relation, if: :self_inverse?
  after_destroy :destroy_inverses, if: :inverse?

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

  def destroy_relation
    self.destroy
  end

  def inverse?
    self.class.exists?(inverse_relation_options) && !self_inverse?
  end

  def inverses
    self.class.where(inverse_relation_options)
  end

  def inverse_relation_options
    { related_tag_id: tag_id, tag_id: related_tag_id }
  end
end
