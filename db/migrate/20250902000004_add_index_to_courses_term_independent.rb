class AddIndexToCoursesTermIndependent < ActiveRecord::Migration[8.0]
  def change
    add_index :courses, :term_independent
  end
end
