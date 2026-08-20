class CreateAssessmentTaskPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_task_points, id: :uuid do |t|
      t.uuid :assessment_participation_id, null: false
      t.uuid :task_id, null: false

      t.decimal :points, precision: 10, scale: 2
      t.text :comment
      t.bigint :grader_id
      t.uuid :submission_id

      t.timestamps
    end

    add_index :assessment_task_points, :assessment_participation_id,
              name: "index_task_points_on_participation"
    add_index :assessment_task_points, :task_id
    add_index :assessment_task_points, :grader_id
    add_index :assessment_task_points, :submission_id
    add_index :assessment_task_points, [:assessment_participation_id, :task_id],
              unique: true, name: "index_task_points_on_participation_and_task"
    add_foreign_key :assessment_task_points, :assessment_participations,
                    column: :assessment_participation_id
    add_foreign_key :assessment_task_points, :assessment_tasks,
                    column: :task_id
    add_foreign_key :assessment_task_points, :users, column: :grader_id
    add_foreign_key :assessment_task_points, :submissions
  end
end
