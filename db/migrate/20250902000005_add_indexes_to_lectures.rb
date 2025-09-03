class AddIndexesToLectures < ActiveRecord::Migration[8.0]
  def change
    add_index :lectures, :sort
    add_index :lectures, :released
  end
end
