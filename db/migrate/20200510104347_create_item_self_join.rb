# rubocop:disable Rails/
class CreateItemSelfJoin < ActiveRecord::Migration[6.0]
  def change
    create_table :item_self_joins do |t|
      t.references :item, null: false
      t.references :related_item, null: false
    end
  end
end
# rubocop:enable Rails/
