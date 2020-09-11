class CreateUserSubmissionJoins < ActiveRecord::Migration[6.0]
  def change
    create_table :user_submission_joins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :submission, null: false, foreign_key: true

      t.timestamps
    end
  end
end
