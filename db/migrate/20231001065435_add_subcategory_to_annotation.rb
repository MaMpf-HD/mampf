class AddSubcategoryToAnnotation < ActiveRecord::Migration[7.0]
  def change
    add_column :annotations, :subcategory, :integer
  end
end
