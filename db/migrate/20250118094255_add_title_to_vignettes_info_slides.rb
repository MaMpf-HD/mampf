class AddTitleToVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_info_slides, :title, :string
  end
end
