# Connection class
class Connection < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :linked_asset, class_name: 'LearningAsset'

  validates :linked_asset, uniqueness: { scope: :learning_asset,
                                         message: 'connection already exists' }
  validate :no_self_connections_allowed

  private

  def no_self_connections_allowed
    return unless learning_asset_id == linked_asset_id
    errors.add(:base, 'no self connectionss allowed')
  end
end
