class AddUniqueIndexOnAchievementTitle < ActiveRecord::Migration[8.0]
  def change
    add_index :achievements, [:lecture_id, :title], unique: true,
              name: "index_achievements_on_lecture_and_title"
  end
end
