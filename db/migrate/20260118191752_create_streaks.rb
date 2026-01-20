class CreateStreaks < ActiveRecord::Migration[8.0]
  def change
    create_table :streaks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :streakable, polymorphic: true, null: false

      t.integer :value, default: 0, null: false
      t.date :last_activity, default: Time.current.prev_week, null: false

      t.timestamps
    end
  end
end
