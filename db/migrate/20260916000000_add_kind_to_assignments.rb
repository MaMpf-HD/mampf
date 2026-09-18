# A sheet is homework unless it is a test written in the tutorial; nothing
# else about the row changes, so every existing sheet is homework.
class AddKindToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :kind, :integer, default: 0, null: false
  end
end
