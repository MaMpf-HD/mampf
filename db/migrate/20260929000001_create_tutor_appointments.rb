# Tutors that the staff of a lecture added by the address of their account,
# before or without a group: what a redeemed tutor voucher records otherwise.
class CreateTutorAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :tutor_appointments do |t|
      t.references :lecture, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :tutor_appointments, [:lecture_id, :user_id], unique: true
  end
end
