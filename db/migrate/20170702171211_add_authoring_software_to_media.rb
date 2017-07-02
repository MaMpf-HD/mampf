class AddAuthoringSoftwareToMedia < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :authoring_software, :string  
  end
end
