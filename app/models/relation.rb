class Relation < ApplicationRecord
  belongs_to :tag
  belongs_to :related_tag, class_name: "Tag"

  after_create :create_inverse, unless: :has_inverse?
  after_destroy :destroy_inverses, if: :has_inverse?

  def create_inverse
    self.class.create(inverse_relation_options)
  end

  def destroy_inverses
    inverses.destroy_all
  end

  def has_inverse?
    self.class.exists?(inverse_relation_options)
  end

  def inverses
    self.class.where(inverse_relation_options)
  end

  def inverse_relation_options
    { related_tag_id: tag_id, tag_id: related_tag_id }
  end
end
