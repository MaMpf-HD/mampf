class RemoveProgramFromCourse < ActiveRecord::Migration[6.0]
  def change
    remove_reference :courses, :program, foreign_key: true
  end
end
