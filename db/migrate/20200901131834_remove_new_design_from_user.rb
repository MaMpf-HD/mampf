class RemoveNewDesignFromUser < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :new_design, :boolean
  end
end
