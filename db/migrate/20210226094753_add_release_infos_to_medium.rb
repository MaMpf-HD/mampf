# rubocop:disable Rails/
class AddReleaseInfosToMedium < ActiveRecord::Migration[6.0]
  def up
    add_column :media, :released_at, :datetime
    add_column :media, :release_date, :datetime

    Medium.where(released: ["all", "users", "subscribers"]).each do |m|
      m.update_columns(released_at: m.created_at)
    end
  end

  def down
    remove_column :media, :released_at, :datetime
    remove_column :media, :release_date, :datetime
  end
end
# rubocop:enable Rails/
