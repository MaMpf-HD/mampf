class CreateClaims < ActiveRecord::Migration[7.1]
  def change
    create_table :claims do |t|
      t.references :redemption, null: false, foreign_key: true
      t.references :claimable, polymorphic: true, null: false
      t.timestamps
    end
  end
end
