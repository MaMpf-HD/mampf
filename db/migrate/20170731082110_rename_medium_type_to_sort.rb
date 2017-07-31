class RenameMediumTypeToSort < ActiveRecord::Migration[5.1]
  def change
    rename_column :media, :type, :sort
  end
end
