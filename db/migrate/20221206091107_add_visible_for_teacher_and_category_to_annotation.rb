class AddVisibleForTeacherAndCategoryToAnnotation < ActiveRecord::Migration[6.1]
  def change
    add_column :annotations, :visible_for_teacher, :boolean
    add_column :annotations, :category, :integer
  end
end
