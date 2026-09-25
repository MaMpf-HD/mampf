class AddLectureIndexToTutorialMemberships < ActiveRecord::Migration[8.0]
  def change
    add_index :tutorial_memberships, :lecture_id
  end
end
