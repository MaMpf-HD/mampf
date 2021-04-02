class RemoveReleaseDateFromMedium < ActiveRecord::Migration[6.0]
  def up
    remove_column :media, :release_date, :datetime
  end

  def down
    add_column :media, :release_date, :datetime
  end
end
