class RemoveNumbersFromSection < ActiveRecord::Migration[5.2]
  def change
    remove_column :sections, :number, :integer # rubocop:todo Rails/BulkChangeTable
    remove_column :sections, :number_alt, :string
  end
end
