class CreateCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :completions do |t|
      t.references :lecture, null: false, foreign_key: true
      t.references :completable, null: false, polymorphic: true
      t.references :user, null: false, foreign_key: true

      t.timestamps

      t.index [:lecture_id, :user_id]
      t.index [:completable_type, :completable_id, :user_id],
              unique: true,
              name: "index_completions_on_completable_and_user"
    end
  end
end
