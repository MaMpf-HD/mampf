# rubocop:disable Rails/
class AddMailPropertiesToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :email_for_medium, :boolean
    add_column :users, :email_for_announcement, :boolean
    add_column :users, :email_for_teachable, :boolean
    add_column :users, :email_for_news, :boolean
  end
end
# rubocop:enable Rails/
