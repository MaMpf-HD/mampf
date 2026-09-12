class VignettesBecomeALectureProperty < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :vignettes, :boolean, default: false, null: false

    add_column :vignettes_questionnaires, :data_collection, :boolean,
               default: false, null: false

    # The codename is deliberately not tied to an account: the link between a
    # person and their answers exists only on the note the student keeps.
    remove_reference :vignettes_codenames, :user, type: :bigint, index: true
    remove_reference :vignettes_codenames, :lecture, type: :bigint, index: true
    change_column_null :vignettes_codenames, :pseudonym, false
    add_index :vignettes_codenames, :pseudonym, unique: true

    remove_reference :vignettes_user_answers, :user,
                     type: :bigint, null: false, index: true
    add_reference :vignettes_user_answers, :vignettes_codename,
                  null: false, foreign_key: { to_table: :vignettes_codenames }

    remove_reference :vignettes_slide_statistics, :user,
                     type: :bigint, null: false, index: true
    change_column_null :vignettes_slide_statistics, :vignettes_answer_id, false

    drop_table :vignettes_completion_messages do |t|
      t.bigint :lecture_id, null: false, index: true
      t.timestamps
    end
  end
end
