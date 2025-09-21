class RemoveQuizzableFromMedia < ActiveRecord::Migration[8.0]
  def change
    remove_reference :media, :quizzable, polymorphic: true, index: true
  end
end
