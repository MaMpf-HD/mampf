class RemoveQuestionableFromVignettesSlides < ActiveRecord::Migration[7.1]
  def change
    remove_index :vignettes_slides, name: "index_vignettes_slides_on_questionable"
    remove_column :vignettes_slides, :questionable_type, :string
    remove_column :vignettes_slides, :questionable_id, :bigint
  end
end
