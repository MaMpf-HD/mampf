# rubocop:disable Rails/
class AddOrganizationalToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :organizational, :boolean
  end
end
# rubocop:enable Rails/
