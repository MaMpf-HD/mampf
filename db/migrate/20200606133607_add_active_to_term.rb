# rubocop:disable Rails/
class AddActiveToTerm < ActiveRecord::Migration[6.0]
  def change
    add_column :terms, :active, :boolean, default: false
  end
end
# rubocop:enable Rails/
