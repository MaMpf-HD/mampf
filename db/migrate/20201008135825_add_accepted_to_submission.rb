class AddAcceptedToSubmission < ActiveRecord::Migration[6.0]
  def up
    add_column :submissions, :accepted, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end

  def down
    remove_column :submissions, :accepted, :boolean
  end
end
