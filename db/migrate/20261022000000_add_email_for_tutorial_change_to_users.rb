class AddEmailForTutorialChangeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_for_tutorial_change, :boolean, default: true, null: false
  end
end
