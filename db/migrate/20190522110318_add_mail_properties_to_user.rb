class AddMailPropertiesToUser < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_medium, :boolean # rubocop:todo Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
    # rubocop:enable Rails/ThreeStateBooleanColumn
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_announcement, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_teachable, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_news, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
