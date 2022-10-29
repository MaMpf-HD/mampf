class AddHomepageToTeacher < ActiveRecord::Migration[5.1]
  def change
    add_column :teachers, :homepage, :text
  end
end
