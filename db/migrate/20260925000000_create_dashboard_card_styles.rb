class CreateDashboardCardStyles < ActiveRecord::Migration[8.0]
  def change
    create_table :dashboard_card_styles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lecture, null: false, foreign_key: true
      t.integer :tape_color, null: false, default: 0

      t.timestamps
    end

    add_index :dashboard_card_styles, [:user_id, :lecture_id], unique: true
  end
end
