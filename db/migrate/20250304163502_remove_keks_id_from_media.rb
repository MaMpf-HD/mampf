class RemoveKeksIdFromMedia < ActiveRecord::Migration[7.2]
  # The keks_id column has never been actually used, so if this migration
  # needs to be reverted, no harm is done.
  def change
    remove_column :media, :keks_id, :integer
  end
end
