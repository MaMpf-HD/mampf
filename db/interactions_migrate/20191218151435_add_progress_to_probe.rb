class AddProgressToProbe < ActiveRecord::Migration[6.0]
  def change
    add_column :probes, :progress, :integer
  end
end
