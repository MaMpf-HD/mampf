class RemoveAllowVisibleAnnotationsFromMedium < ActiveRecord::Migration[6.1]
  def change
    remove_column :media, :allow_visible_annotations
  end
end
