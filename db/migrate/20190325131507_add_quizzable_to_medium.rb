class AddQuizzableToMedium < ActiveRecord::Migration[5.2]
  def change
    add_reference :media, :quizzable, polymorphic: true
  end
end
