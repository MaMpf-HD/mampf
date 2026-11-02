class AddTutorEmailsToStudentMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :student_messages, :tutor_emails, :string, array: true, default: [], null: false
  end
end
