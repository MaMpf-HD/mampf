# rubocop:disable Rails/
class AddReleasedToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :released, :text
    Lecture.all.update_all(released: "all")
  end
end
# rubocop:enable Rails/
