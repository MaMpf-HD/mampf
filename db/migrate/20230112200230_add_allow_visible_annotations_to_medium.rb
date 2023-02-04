class AddAllowVisibleAnnotationsToMedium < ActiveRecord::Migration[6.1]
  def change
    add_column :media, :allow_visible_annotations, :integer
  end
end
