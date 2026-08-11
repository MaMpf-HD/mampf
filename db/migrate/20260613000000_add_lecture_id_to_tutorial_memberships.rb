class AddLectureIdToTutorialMemberships < ActiveRecord::Migration[8.0]
  def up
    add_column :tutorial_memberships, :lecture_id, :bigint, null: false
    add_index :tutorial_memberships,
              [:user_id, :lecture_id],
              unique: true,
              name: "index_tutorial_memberships_on_user_id_and_lecture_id"
    add_foreign_key :tutorial_memberships, :lectures
  end

  def down
    remove_foreign_key :tutorial_memberships, :lectures
    remove_index :tutorial_memberships,
                 name: "index_tutorial_memberships_on_user_id_and_lecture_id"
    remove_column :tutorial_memberships, :lecture_id
  end
end
