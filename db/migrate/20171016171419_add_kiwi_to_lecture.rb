class AddKiwiToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :kiwi, :boolean
  end
end
