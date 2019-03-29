class RemoveLabelFromRemark < ActiveRecord::Migration[5.2]
  def change
    remove_column :remarks, :label, :text
  end
end
