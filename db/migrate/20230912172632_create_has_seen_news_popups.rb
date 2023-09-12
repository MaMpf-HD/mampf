class CreateHasSeenNewsPopups < ActiveRecord::Migration[7.0]
  def change
    create_table :has_seen_news_popups do |t|
      t.references :user, null: false, foreign_key: true
      t.references :news_popup, null: false, foreign_key: true

      t.timestamps
    end
  end
end
