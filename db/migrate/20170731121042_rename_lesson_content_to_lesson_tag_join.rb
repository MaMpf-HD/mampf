class RenameLessonContentToLessonTagJoin < ActiveRecord::Migration[5.1]
  def change
    rename_table :lesson_contents, :lesson_tag_joins
  end
end
