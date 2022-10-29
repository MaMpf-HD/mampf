class AddLockableToDevise < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :locked_at, :datetime
  end

  def down
    remove_column :users, :loccked_at, :datetime
  end
end
