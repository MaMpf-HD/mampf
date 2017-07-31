class RenameTermTypeToSeason < ActiveRecord::Migration[5.1]
  def change
    rename_column :terms, :type, :season
  end
end
