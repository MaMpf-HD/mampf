# rubocop:disable Rails/
class AddMuesliToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :muesli, :boolean
  end
end
# rubocop:enable Rails/
