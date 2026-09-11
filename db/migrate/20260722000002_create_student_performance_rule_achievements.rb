class CreateStudentPerformanceRuleAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :student_performance_rule_achievements, id: :uuid do |t|
      t.uuid :rule_id, null: false
      t.bigint :achievement_id, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :student_performance_rule_achievements,
              [:rule_id, :achievement_id],
              unique: true,
              name: "index_rule_achievements_on_rule_and_achievement"
    add_index :student_performance_rule_achievements, :achievement_id,
              name: "index_rule_achievements_on_achievement"
    add_foreign_key :student_performance_rule_achievements,
                    :student_performance_rules, column: :rule_id
    add_foreign_key :student_performance_rule_achievements,
                    :achievements, column: :achievement_id,
                                   on_delete: :restrict
  end
end
