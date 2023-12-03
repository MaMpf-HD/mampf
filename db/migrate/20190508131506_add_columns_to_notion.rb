class AddColumnsToNotion < ActiveRecord::Migration[6.0]
  def change
    add_column :notions, :title, :text # rubocop:todo Rails/BulkChangeTable
    add_column :notions, :locale, :text
  end
end
