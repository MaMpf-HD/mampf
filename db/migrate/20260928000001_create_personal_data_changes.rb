# Keeps who corrected which of a user's locked personal data, and from what
# to what, since exam lists and grade exports go by it.
class CreatePersonalDataChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_data_changes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :editor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :field, null: false
      t.string :old_value
      t.string :new_value
      t.datetime :created_at, null: false
    end
  end
end
