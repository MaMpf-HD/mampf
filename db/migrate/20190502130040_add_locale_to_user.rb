class AddLocaleToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :locale, :text
  end
end
