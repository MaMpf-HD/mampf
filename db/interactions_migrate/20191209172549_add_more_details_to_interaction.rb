class AddMoreDetailsToInteraction < ActiveRecord::Migration[6.0]
  def change
    add_column :interactions, :full_path, :text
  end
end
