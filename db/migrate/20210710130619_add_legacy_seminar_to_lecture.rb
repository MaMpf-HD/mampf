# rubocop:disable Rails/
class AddLegacySeminarToLecture < ActiveRecord::Migration[6.1]
  def up
    add_column :lectures, :legacy_seminar, :boolean, default: false
    Lecture.seminar.update_all(legacy_seminar: true)
  end

  def down
    remove_column :lectures, :legacy_seminar, :boolean, default: false
  end
end
# rubocop:enable Rails/
