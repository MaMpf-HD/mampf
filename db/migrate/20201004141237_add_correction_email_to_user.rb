class AddCorrectionEmailToUser < ActiveRecord::Migration[6.0]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_correction_upload, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end

  def down
    remove_column :users, :email_for_correction_upload, :boolean
  end
end
