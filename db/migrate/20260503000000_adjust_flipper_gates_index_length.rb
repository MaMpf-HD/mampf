class AdjustFlipperGatesIndexLength < ActiveRecord::Migration[8.0]
  def change
    remove_index :flipper_gates, column: [:feature_key, :key, :value]
    add_index :flipper_gates, [:feature_key, :key, :value],
              unique: true,
              length: { value: 255 }
  end
end
