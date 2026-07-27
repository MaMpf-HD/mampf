class CreateRegistrationStudentMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_student_messages do |t|
      t.references :lecture, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.string :subject, null: false
      t.text :body, null: false
      t.text :attachment_data
      t.string :recipient_emails, null: false, default: [], array: true
      t.integer :recipients_count, null: false, default: 0

      t.timestamps
    end
  end
end
