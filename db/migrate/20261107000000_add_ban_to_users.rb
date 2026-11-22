class AddBanToUsers < ActiveRecord::Migration[8.0]
  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  def change
    add_column :users, :banned_at, :datetime
    add_reference :users, :banned_by,
                  foreign_key: { to_table: :users, on_delete: :nullify }
    add_column :users, :ban_reason, :text

    add_check_constraint :users, "(banned_at IS NULL) = (ban_reason IS NULL)",
                         name: "users_ban_has_reason"
    add_check_constraint :users, "banned_by_id IS NULL OR banned_at IS NOT NULL",
                         name: "users_banned_by_only_with_ban"

    reversible do |direction|
      direction.down { refuse_to_drop_bans! }
    end
  end

  private

    def refuse_to_drop_bans!
      return unless User.where.not(banned_at: nil).exists?

      raise(ActiveRecord::IrreversibleMigration,
            "users holds bans; lift them first")
    end
end
