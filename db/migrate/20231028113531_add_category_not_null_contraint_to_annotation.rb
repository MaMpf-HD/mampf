class AddCategoryNotNullContraintToAnnotation < ActiveRecord::Migration[7.0]
  def change
    change_column_null :annotations, :category, false
  end
end
