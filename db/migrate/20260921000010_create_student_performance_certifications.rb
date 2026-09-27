class CreateStudentPerformanceCertifications < ActiveRecord::Migration[8.0]
  def change
    create_table :student_performance_certifications, id: :uuid do |t|
      t.bigint :lecture_id, null: false
      t.bigint :user_id, null: false
      t.integer :status, default: 0, null: false
      t.integer :source, default: 0, null: false
      t.bigint :certified_by_id
      t.datetime :certified_at
      t.uuid :rule_id
      t.text :note

      t.timestamps
    end

    add_index :student_performance_certifications,
              [:lecture_id, :user_id],
              unique: true,
              name: "index_certifications_on_lecture_and_user"
    add_index :student_performance_certifications, :user_id,
              name: "index_certifications_on_user"
    add_index :student_performance_certifications, :certified_by_id,
              name: "index_certifications_on_certified_by"
    add_index :student_performance_certifications, :rule_id,
              name: "index_certifications_on_rule"
    add_foreign_key :student_performance_certifications, :lectures
    add_foreign_key :student_performance_certifications, :users
    add_foreign_key :student_performance_certifications, :users,
                    column: :certified_by_id
    add_foreign_key :student_performance_certifications,
                    :student_performance_rules, column: :rule_id
  end
end
