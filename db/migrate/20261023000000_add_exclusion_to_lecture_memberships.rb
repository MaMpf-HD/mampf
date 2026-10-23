class AddExclusionToLectureMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :lecture_memberships, :excluded_at, :datetime
    add_reference :lecture_memberships, :excluded_by,
                  foreign_key: { to_table: :users, on_delete: :nullify }
    add_index :lecture_memberships, [:lecture_id, :excluded_at]
  end
end
