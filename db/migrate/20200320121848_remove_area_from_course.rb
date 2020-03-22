class RemoveAreaFromCourse < ActiveRecord::Migration[6.0]
  def change
    remove_reference :courses, :area, foreign_key: true
  end
end
