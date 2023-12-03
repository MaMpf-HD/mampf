# rubocop:disable Rails/
class AddCommentsDisabledToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :comments_disabled, :boolean
  end
end
# rubocop:enable Rails/
