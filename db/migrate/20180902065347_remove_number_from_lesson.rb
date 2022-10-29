class RemoveNumberFromLesson < ActiveRecord::Migration[5.2]
  def change
    remove_column :lessons, :number, :integer
  end
end
