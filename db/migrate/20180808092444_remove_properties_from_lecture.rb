class RemovePropertiesFromLecture < ActiveRecord::Migration[5.2]
  def change
    remove_column :lectures, :kaviar, :boolean
    remove_column :lectures, :sesam, :boolean
    remove_column :lectures, :keks, :boolean
    remove_column :lectures, :reste, :boolean
    remove_column :lectures, :erdbeere, :boolean
    remove_column :lectures, :kiwi, :boolean
  end
end
