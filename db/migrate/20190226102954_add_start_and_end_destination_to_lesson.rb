class AddStartAndEndDestinationToLesson < ActiveRecord::Migration[5.2]
  def change
    add_column :lessons, :start_destination, :text # rubocop:todo Rails/BulkChangeTable
    add_column :lessons, :end_destination, :text
  end
end
