class AddForeignKeysToMedium < ActiveRecord::Migration[5.1]
  def change
    change_table :media do |t|
      t.actable
    end
  end
end
