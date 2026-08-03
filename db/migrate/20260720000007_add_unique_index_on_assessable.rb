class AddUniqueIndexOnAssessable < ActiveRecord::Migration[8.0]
  def change
    remove_index :assessment_assessments, [:assessable_type, :assessable_id],
                 name: "index_assessments_on_assessable"
    add_index :assessment_assessments, [:assessable_type, :assessable_id],
              unique: true, name: "index_assessments_on_assessable"
  end
end
