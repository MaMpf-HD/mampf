# rubocop:disable Rails/
class AddStartAndEndDestinationToLesson < ActiveRecord::Migration[5.2]
  def change
    add_column :lessons, :start_destination, :text
    add_column :lessons, :end_destination, :text
  end
end
# rubocop:enable Rails/
