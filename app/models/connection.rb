# Connection class
# JoinTable for asset<->asset many-to-many-relation
class Connection < ApplicationRecord
  belongs_to :asset
  belongs_to :linked_asset, class_name: 'Asset'

  validates :linked_asset, uniqueness: { scope: :asset,
                                         message: 'connection already exists' }
  validate :no_self_connections_allowed

  private

  def no_self_connections_allowed
    return unless asset_id == linked_asset_id
    errors.add(:base, 'no self connections allowed')
  end
end
