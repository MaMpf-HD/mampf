# A message goes to the groups its sender picked, not to everybody who
# registered; the record says which, and who sent it - the lecture's staff
# or a tutor writing to their own group.
class RenameStudentMessagesAndAddAudiences < ActiveRecord::Migration[8.0]
  def change
    rename_table :registration_student_messages, :student_messages
    add_column :student_messages, :audiences, :jsonb, null: false, default: []
    add_column :student_messages, :sender_role, :integer, null: false, default: 0
  end
end
