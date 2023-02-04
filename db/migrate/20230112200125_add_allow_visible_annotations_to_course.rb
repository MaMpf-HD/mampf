class AddAllowVisibleAnnotationsToCourse < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :allow_visible_annotations, :integer
  end
end
