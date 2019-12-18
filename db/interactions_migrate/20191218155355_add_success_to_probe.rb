class AddSuccessToProbe < ActiveRecord::Migration[6.0]
  def change
    add_column :probes, :success, :integer
  end
end
