class AddTextInputToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :text_input, :boolean, default: false
  end
end
