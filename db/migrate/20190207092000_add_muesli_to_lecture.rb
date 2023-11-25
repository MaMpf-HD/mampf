class AddMuesliToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :muesli, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
