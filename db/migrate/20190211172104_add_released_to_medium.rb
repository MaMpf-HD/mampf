# rubocop:disable Rails/
class AddReleasedToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :released, :text
    Medium.all.update_all(released: "all")
  end
end
# rubocop:enable Rails/
