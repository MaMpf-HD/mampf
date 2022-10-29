class AddGeogebraDataToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :geogebra_data, :text
  end
end
