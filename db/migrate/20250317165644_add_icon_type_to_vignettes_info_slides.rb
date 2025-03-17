class AddIconTypeToVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_info_slides, :icon_type, :string
  end
end
