class RemoveAllowVisibleAnnotationsFromCourse < ActiveRecord::Migration[6.1]
  def change
    remove_column :courses, :allow_visible_annotations
  end
end
