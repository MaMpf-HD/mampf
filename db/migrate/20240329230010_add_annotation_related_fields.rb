class AddAnnotationRelatedFields < ActiveRecord::Migration[7.0]
  def change
    # Annotations status
    # Media inherits annotation status from lecture by default
    add_column :media, :annotations_status, :integer, default: -1, null: false
    # Lecture: activate "share annotation with lecturer" feature by default
    add_column :lectures, :annotations_status, :integer, default: 1, null: false

    # Emergency Link
    change_table :lectures, bulk: true do |t|
      t.integer :emergency_link_status, default: 0, null: false
      t.text :emergency_link
    end
  end
end
