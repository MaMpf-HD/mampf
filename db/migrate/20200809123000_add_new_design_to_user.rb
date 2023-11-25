class AddNewDesignToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :new_design, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
