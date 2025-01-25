class AddIconToVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_info_slides, :icon, :string
  end
end
