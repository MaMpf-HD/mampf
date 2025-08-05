class AddAnswersCountToMedia < ActiveRecord::Migration[8.0]
  def change
    add_column :media, :answers_count, :integer, default: 0, null: false
    add_index :media, :answers_count
  end
  # NOTE: After the migration, run rails data:reset_answers_count
  # once in order to set all answer_counts correctly. This has been placed
  # outside of this migration deliberately as details of the model
  # implementation may change but the migration should run anyway.
end
