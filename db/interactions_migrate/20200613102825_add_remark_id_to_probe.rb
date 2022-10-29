class AddRemarkIdToProbe < ActiveRecord::Migration[6.0]
  def change
    add_column :probes, :remark_id, :integer
  end
end
