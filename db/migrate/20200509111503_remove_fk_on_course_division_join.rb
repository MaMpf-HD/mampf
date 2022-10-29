class RemoveFkOnCourseDivisionJoin < ActiveRecord::Migration[6.0]
  def change
    if foreign_key_exists?(:division_course_joins, :divisions)
      remove_foreign_key :division_course_joins, :divisions
    end
    if foreign_key_exists?(:division_course_joins, :courses)
      remove_foreign_key :division_course_joins, :courses
    end
  end
end
