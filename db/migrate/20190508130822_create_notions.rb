# rubocop:disable Style/SymbolProc
class CreateNotions < ActiveRecord::Migration[6.0]
  def change
    create_table :notions do |t|
      t.timestamps
    end
  end
end
# rubocop:enable Style/SymbolProc
