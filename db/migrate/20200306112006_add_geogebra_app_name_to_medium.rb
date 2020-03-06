class AddGeogebraAppNameToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :geogebra_app_name, :text
  end
end
