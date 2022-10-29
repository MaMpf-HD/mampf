class RemoveTeachableFromClicker < ActiveRecord::Migration[6.0]
  def change
    remove_reference :clickers, :teachable, polymorphic: true, null: false
  end
end
