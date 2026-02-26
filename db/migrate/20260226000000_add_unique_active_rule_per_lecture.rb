class AddUniqueActiveRulePerLecture < ActiveRecord::Migration[8.0]
  def change
    add_index :student_performance_rules, :lecture_id,
              unique: true,
              where: "active = true",
              name: "index_sp_rules_one_active_per_lecture"
  end
end
