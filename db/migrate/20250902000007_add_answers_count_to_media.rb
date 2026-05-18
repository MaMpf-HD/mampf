class AddAnswersCountToMedia < ActiveRecord::Migration[8.0]
  def change
    add_column :media, :answers_count, :integer, default: 0, null: false
    add_index :media, :answers_count
  end
end
