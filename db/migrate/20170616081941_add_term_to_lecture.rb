class AddTermToLecture < ActiveRecord::Migration[5.1]
  def change
    add_reference :lectures, :term, foreign_key: true
  end
end
