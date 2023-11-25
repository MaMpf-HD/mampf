# ItemSelfJoin class
# JoinTable for item<->item many-to-many-relation
# that describes items which refer to equivalent content
# (e.g. a proposition in a medium of type script and the same proposition
# in a lesson medium)
class ItemSelfJoin < ApplicationRecord
  belongs_to :item
  belongs_to :related_item, class_name: "Item"

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :related_item, uniqueness: { scope: :item }
  before_destroy :touch_item
  after_destroy :destroy_inverses, if: :inverse?
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  after_save :create_inverse, unless: :inverse?
  after_save :destroy, if: :self_inverse?
  after_save :touch_item

  private

    def create_inverse
      self.class.create(inverse_relation_options)
    end

    def destroy_inverses
      inverses.destroy_all
    end

    def self_inverse?
      item_id == related_item_id
    end

    def inverse?
      self.class.exists?(inverse_relation_options) || self_inverse?
    end

    def inverses
      self.class.where(inverse_relation_options)
    end

    def inverse_relation_options
      { related_item_id: item_id, item_id: related_item_id }
    end

    def touch_item
      return if item.nil?

      item.touch # rubocop:todo Rails/SkipsModelValidations
    end
end
