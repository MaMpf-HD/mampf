class AddMissingUniqueConstraintsToJoins < ActiveRecord::Migration[8.0]
  def up
    LectureUserJoin
      .where.not(id: LectureUserJoin.select("MIN(id)").group(:lecture_id, :user_id))
      .delete_all

    TutorTutorialJoin
      .where.not(id: TutorTutorialJoin.select("MIN(id)").group(:tutorial_id, :tutor_id))
      .delete_all

    add_index :lecture_user_joins, [:lecture_id, :user_id], unique: true
    add_index :tutor_tutorial_joins, [:tutorial_id, :tutor_id], unique: true
  end

  def down
    remove_index :lecture_user_joins, [:lecture_id, :user_id]
    remove_index :tutor_tutorial_joins, [:tutorial_id, :tutor_id]
  end
end
