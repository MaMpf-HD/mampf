# Connection class
# JoinTable for asset<->asset many-to-many-relation
class Connection < ApplicationRecord
  belongs_to :asset
  belongs_to :linked_asset, class_name: 'Asset'

  validates :linked_asset, uniqueness: { scope: :asset,
                                         message: 'connection already exists' }
  after_create :create_inverse, unless: :inverse?
  after_create :destroy_connection, if: :self_inverse?
  after_destroy :destroy_inverses, if: :inverse?

  private

  def create_inverse
     self.class.create(inverse_connection_options)
  end

  def destroy_inverses
    inverses.destroy_all
  end

  def self_inverse?
    asset_id == linked_asset_id
  end

  def destroy_connection
    self.destroy
  end

  def inverse?
    self.class.exists?(inverse_connection_options) && !self_inverse?
  end

  def inverses
    self.class.where(inverse_connection_options)
  end

  def inverse_connection_options
    { linked_asset_id: asset_id, asset_id: linked_asset_id }
  end
end
