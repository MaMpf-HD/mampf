class AddAreaAndProgramToCourse < ActiveRecord::Migration[6.0]
  def change
    add_reference :courses, :area, foreign_key: true
    add_reference :courses, :program, foreign_key: true
  end
end
