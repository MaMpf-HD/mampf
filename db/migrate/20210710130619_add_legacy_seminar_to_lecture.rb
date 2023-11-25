class AddLegacySeminarToLecture < ActiveRecord::Migration[6.1]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :legacy_seminar, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
    Lecture.seminar.update_all(legacy_seminar: true) # rubocop:todo Rails/SkipsModelValidations
  end

  def down
    remove_column :lectures, :legacy_seminar, :boolean, default: false
  end
end
