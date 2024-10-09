class CreateRedemptions < ActiveRecord::Migration[7.1]
  def change
    create_table :redemptions do |t|
      t.references :voucher, type: :uuid, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
