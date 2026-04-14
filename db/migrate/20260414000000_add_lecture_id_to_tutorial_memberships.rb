class AddLectureIdToTutorialMemberships < ActiveRecord::Migration[7.2]
  def up
    add_column :tutorial_memberships, :lecture_id, :bigint

    # rubocop:disable Rails/SkipsModelValidations
    TutorialMembership.update_all(
      "lecture_id = " \
      "(SELECT lecture_id FROM tutorials WHERE tutorials.id = tutorial_memberships.tutorial_id)"
    )
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null :tutorial_memberships, :lecture_id, false

    # Keep the most recently updated membership per (user, lecture) pair.
    TutorialMembership
      .where.not(id: TutorialMembership
        .select("DISTINCT ON (user_id, lecture_id) id")
        .order(:user_id, :lecture_id, updated_at: :desc))
      .delete_all

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
