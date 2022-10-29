class AddInputToProbe < ActiveRecord::Migration[6.0]
  def change
    add_column :probes, :input, :text
  end
end
