class RenameLessonHeadingToLessonSectionJoin < ActiveRecord::Migration[5.1]
  def change
    rename_table :lesson_headings, :lesson_section_joins    
  end
end
