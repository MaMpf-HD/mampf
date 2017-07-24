class ChangeLengthinMedium < ActiveRecord::Migration[5.1]
  def change
    change_column :media, :length, :string
  end
end
