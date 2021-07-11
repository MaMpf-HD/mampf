class AddDatesToTalk < ActiveRecord::Migration[6.1]
  def up
    add_column :talks, :dates, :date, array: true, default: []
  end

  def down
    remove_column :talks, :dates, :date, array: true, default: []
  end
end
