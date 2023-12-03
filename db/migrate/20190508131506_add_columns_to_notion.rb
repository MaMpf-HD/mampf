# rubocop:disable Rails/
class AddColumnsToNotion < ActiveRecord::Migration[6.0]
  def change
    add_column :notions, :title, :text
    add_column :notions, :locale, :text
  end
end
# rubocop:enable Rails/
