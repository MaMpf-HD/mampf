class CreateVouchers < ActiveRecord::Migration[7.1]
  def change
    create_table :vouchers, id: :uuid, default: "gen_random_uuid()" do |t|
      t.integer :sort, null: false
      t.references :lecture, null: false, foreign_key: true
      t.string :secure_hash, null: false
      t.datetime :invalidated_at
      t.datetime :expires_at
      t.timestamps
    end
    add_index :vouchers, :secure_hash, unique: true
  end
end
