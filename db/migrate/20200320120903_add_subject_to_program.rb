class AddSubjectToProgram < ActiveRecord::Migration[6.0]
  def change
    add_reference :programs, :subject, foreign_key: true
  end
end
