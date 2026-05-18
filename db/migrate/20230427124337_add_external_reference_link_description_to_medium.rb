class AddExternalReferenceLinkDescriptionToMedium < ActiveRecord::Migration[7.0]
  def change
    add_column :media, :external_link_description, :text
  end
end
