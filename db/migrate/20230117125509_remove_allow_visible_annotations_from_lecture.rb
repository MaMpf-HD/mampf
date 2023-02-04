class RemoveAllowVisibleAnnotationsFromLecture < ActiveRecord::Migration[6.1]
  def change
    remove_column :lectures, :allow_visible_annotations
  end
end
