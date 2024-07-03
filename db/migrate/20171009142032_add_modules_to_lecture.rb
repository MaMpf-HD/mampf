# rubocop:disable Rails/
class AddModulesToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :kaviar, :boolean
    add_column :lectures, :sesam, :boolean
    add_column :lectures, :keks, :boolean
    add_column :lectures, :reste, :boolean
    add_column :lectures, :erdbeere, :boolean
  end
end
# rubocop:enable Rails/
