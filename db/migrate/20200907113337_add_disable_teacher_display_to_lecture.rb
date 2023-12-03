class AddDisableTeacherDisplayToLecture < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :disable_teacher_display, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
