class AddAbsoluteNumberingToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :absolute_numbering, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
