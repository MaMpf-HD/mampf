class AddKiwiToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :kiwi, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
