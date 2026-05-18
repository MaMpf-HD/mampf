class AddDeletionDateToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :deletion_date, :date, null: true, default: nil
  end
end
