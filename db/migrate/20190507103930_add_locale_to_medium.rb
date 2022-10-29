class AddLocaleToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :locale, :text
  end
end
