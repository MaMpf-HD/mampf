class AddTextInputToMedium < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :media, :text_input, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
