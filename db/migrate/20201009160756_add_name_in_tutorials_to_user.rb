class AddNameInTutorialsToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :name_in_tutorials, :text
  end

  def down
    remove_column :users, :name_in_tutorials, :text
  end
end
