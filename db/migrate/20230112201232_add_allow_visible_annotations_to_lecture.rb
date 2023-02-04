class AddAllowVisibleAnnotationsToLecture < ActiveRecord::Migration[6.1]
  def change
    add_column :lectures, :allow_visible_annotations, :integer
  end
end
