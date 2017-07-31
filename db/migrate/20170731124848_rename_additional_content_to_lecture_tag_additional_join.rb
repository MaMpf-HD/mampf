class RenameAdditionalContentToLectureTagAdditionalJoin < ActiveRecord::Migration[5.1]
  def change
    rename_table :additional_contents, :lecture_tag_additional_joins      
  end
end
