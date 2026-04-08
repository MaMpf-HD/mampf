class AddMissingUniqueConstraintsToJoins < ActiveRecord::Migration[8.0]
  def up
    # We use raw SQL here to clean up potential duplicate records before
    # adding the unique indices. Raw SQL has the benefit of being independent
    # of the Rails models, which ensures the migration will work even if the
    # model associations or validations change, and it also provides better
    # performance on large join tables.

    execute <<-SQL.squish
      DELETE FROM lecture_user_joins
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM lecture_user_joins
        GROUP BY lecture_id, user_id
      )
    SQL

    execute <<-SQL.squish
      DELETE FROM tutor_tutorial_joins
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM tutor_tutorial_joins
        GROUP BY tutorial_id, tutor_id
      )
    SQL

    add_index :lecture_user_joins, [:lecture_id, :user_id], unique: true
    add_index :tutor_tutorial_joins, [:tutorial_id, :tutor_id], unique: true
  end

  def down
    remove_index :lecture_user_joins, [:lecture_id, :user_id]
    remove_index :tutor_tutorial_joins, [:tutorial_id, :tutor_id]
  end
end
