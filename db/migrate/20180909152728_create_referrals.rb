class CreateReferrals < ActiveRecord::Migration[5.2]
  def change
    create_table :referrals do |t|
      t.text :start_time
      t.text :end_time
      t.boolean :video # rubocop:todo Rails/ThreeStateBooleanColumn
      t.boolean :manuscript # rubocop:todo Rails/ThreeStateBooleanColumn
      t.text :explanation
      t.references :item, foreign_key: true
      t.references :medium, foreign_key: true

      t.timestamps
    end
  end
end
