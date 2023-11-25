class AddReleasedToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :released, :text
    Lecture.all.update_all(released: "all") # rubocop:todo Rails/SkipsModelValidations
  end
end
