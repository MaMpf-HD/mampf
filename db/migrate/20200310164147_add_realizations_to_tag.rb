class AddRealizationsToTag < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :realizations, :text
  end
end
