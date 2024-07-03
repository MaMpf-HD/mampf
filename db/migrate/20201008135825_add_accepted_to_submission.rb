# rubocop:disable Rails/
class AddAcceptedToSubmission < ActiveRecord::Migration[6.0]
  def up
    add_column :submissions, :accepted, :boolean
  end

  def down
    remove_column :submissions, :accepted, :boolean
  end
end
# rubocop:enable Rails/
