class AddMissingUniqueConstraintsToJoins < ActiveRecord::Migration[8.0]
  def up
    # not executed, as the count is 0 in our production DB
    # LectureUserJoin.where(lecture_id: nil).or(
    #   LectureUserJoin.where(user_id: nil)
    # ).delete_all

    LectureUserJoin
      .where.not(id: LectureUserJoin.select("MIN(id)").group(:lecture_id, :user_id))
      .delete_all

    # not executed, as the count is 0 in our production DB
    # TutorTutorialJoin
    #   .where.not(id: TutorTutorialJoin.select("MIN(id)").group(:tutorial_id, :tutor_id))
    #   .delete_all

    change_column_null :lecture_user_joins, :lecture_id, false
    change_column_null :lecture_user_joins, :user_id, false
    # the tutorial_id and tutor_id columns already have NOT NULL constraints,
    # so we don't need to change them

    add_index :lecture_user_joins, [:lecture_id, :user_id], unique: true
    add_index :tutor_tutorial_joins, [:tutorial_id, :tutor_id], unique: true
  end

  def down
    remove_index :lecture_user_joins, [:lecture_id, :user_id]
    remove_index :tutor_tutorial_joins, [:tutorial_id, :tutor_id]
  end
end
