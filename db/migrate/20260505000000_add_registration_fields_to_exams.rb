class AddRegistrationFieldsToExams < ActiveRecord::Migration[8.0]
  def change
    add_column :exams, :skip_campaigns, :boolean, default: false, null: false
    add_column :exams, :self_materialization_mode, :integer, default: 0

    add_index :exams, :self_materialization_mode
  end
end