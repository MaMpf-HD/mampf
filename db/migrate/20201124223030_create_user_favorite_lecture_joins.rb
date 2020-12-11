class CreateUserFavoriteLectureJoins < ActiveRecord::Migration[6.0]
  def up
    create_table :user_favorite_lecture_joins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lecture, null: false, foreign_key: true

      t.timestamps
    end
  end

  def down
  	drop_table :user_favorite_lecture_joins
  end
end
