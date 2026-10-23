class AddExclusionToLectureMemberships < ActiveRecord::Migration[8.0]
  def up
    add_column :lecture_memberships, :excluded_at, :datetime
    add_reference :lecture_memberships, :excluded_by,
                  foreign_key: { to_table: :users, on_delete: :nullify }
    add_index :lecture_memberships, [:lecture_id, :excluded_at]
    add_column :lecture_memberships, :participation_confirmed_at, :datetime
  end

  # Without the column, everyone who has left would count as a member again.
  def down
    if select_value("SELECT 1 FROM lecture_memberships WHERE excluded_at IS NOT NULL LIMIT 1")
      raise(ActiveRecord::IrreversibleMigration,
            "lecture_memberships holds exclusions; delete or archive those rows first")
    end

    remove_column :lecture_memberships, :participation_confirmed_at
    remove_index :lecture_memberships, [:lecture_id, :excluded_at]
    remove_reference :lecture_memberships, :excluded_by,
                     foreign_key: { to_table: :users, on_delete: :nullify }
    remove_column :lecture_memberships, :excluded_at
  end
end
