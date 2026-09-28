# Marks the few people in the examination office and the dean's office who
# read every lecture's groups, published grades and exam eligibility, without
# the rights of an admin.
class AddRecordsOfficeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :records_office, :boolean, default: false, null: false
  end
end
