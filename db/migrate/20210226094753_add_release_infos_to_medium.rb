class AddReleaseInfosToMedium < ActiveRecord::Migration[6.0]
  def up
    add_column :media, :released_at, :datetime # rubocop:todo Rails/BulkChangeTable
    add_column :media, :release_date, :datetime

    Medium.where(released: ["all", "users", "subscribers"]).each do |m|
      m.update_columns(released_at: m.created_at) # rubocop:todo Rails/SkipsModelValidations
    end
  end

  def down
    remove_column :media, :released_at, :datetime # rubocop:todo Rails/BulkChangeTable
    remove_column :media, :release_date, :datetime
  end
end
