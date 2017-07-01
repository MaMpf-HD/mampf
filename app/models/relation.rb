class Relation < ApplicationRecord
  belongs_to :tag
  belongs_to :related_tag, class_name: 'Tag'

  validates :related_tag, uniqueness: { scope: :tag,
                                        message: 'relation already exists' }
  validate :no_inverses_allowed
  validate :no_self_relations_allowed
  after_destroy :destroy_inverses, if: :has_inverse?

  def no_inverses_allowed
    errors.add(:base, 'inverse relation already exists') if has_inverse?
  end

  def no_self_relations_allowed
    errors.add(:base, 'no self relations allowed') if tag_id == related_tag_id
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
