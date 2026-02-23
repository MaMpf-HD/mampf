class AddPointsStepToGradeSchemes < ActiveRecord::Migration[7.1]
  def change
    add_column :assessment_grade_schemes, :points_step,
               :decimal, precision: 10, scale: 2,
                         null: false, default: 1
  end
end
