class RenameDisabledContentToLectureTagDisabledJoin < ActiveRecord::Migration[5.1]
  def change
    rename_table :disabled_contents, :lecture_tag_disabled_joins          
  end
end
