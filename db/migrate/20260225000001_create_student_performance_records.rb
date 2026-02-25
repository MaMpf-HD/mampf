class CreateStudentPerformanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :student_performance_records, id: :uuid do |t|
      t.bigint :lecture_id, null: false
      t.bigint :user_id, null: false
      t.decimal :points_total_materialized, precision: 10, scale: 2
      t.decimal :points_max_materialized, precision: 10, scale: 2
      t.decimal :percentage_materialized, precision: 5, scale: 2
      t.jsonb :achievements_met_ids, default: []
      t.datetime :computed_at

      t.timestamps
    end

    add_index :student_performance_records, [:lecture_id, :user_id],
              unique: true,
              name: "index_performance_records_on_lecture_and_user"
    add_index :student_performance_records, :user_id
    add_foreign_key :student_performance_records, :lectures
    add_foreign_key :student_performance_records, :users
  end
end
