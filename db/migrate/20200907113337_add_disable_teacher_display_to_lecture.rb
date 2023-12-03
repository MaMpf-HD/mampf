# rubocop:disable Rails/
class AddDisableTeacherDisplayToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :disable_teacher_display, :boolean, default: false
  end
end
# rubocop:enable Rails/
