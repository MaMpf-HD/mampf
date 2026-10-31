class AddExclusionToLectureMemberships < ActiveRecord::Migration[8.0]
  class LectureMembership < ActiveRecord::Base
    self.table_name = "lecture_memberships"
  end

  def change
    add_column :lecture_memberships, :excluded_at, :datetime
    add_reference :lecture_memberships, :excluded_by,
                  foreign_key: { to_table: :users, on_delete: :nullify }
    add_index :lecture_memberships, [:lecture_id, :excluded_at]

    reversible do |direction|
      direction.down { refuse_to_drop_exclusions! }
    end
  end

  private

    def refuse_to_drop_exclusions!
      return unless LectureMembership.where.not(excluded_at: nil).exists?

      raise(ActiveRecord::IrreversibleMigration,
            "lecture_memberships holds exclusions; delete or archive those rows first")
    end
end
