class Relation < ApplicationRecord
  belongs_to :tag
  belongs_to :related_tag, class_name: 'Tag'

  before_validation :cancel_saving_duplicate, if: :has_inverse?
  after_destroy :destroy_inverses, if: :has_inverse?

  def destroy_inverses
    inverses.destroy_all
  end

  def has_inverse?
    self.class.exists?(inverse_relation_options)
  end

  def inverses
    self.class.where(inverse_relation_options)
  end

  def cancel_saving_duplicate
    errors.add(:base, 'inverse relation already exists')
    throw :abort
  end

  def inverse_relation_options
    { related_tag_id: tag_id, tag_id: related_tag_id }
  end
end
