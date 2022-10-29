class AddCorrectionEmailToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :email_for_correction_upload, :boolean
  end

  def down
  	remove_column :users, :email_for_correction_upload, :boolean
  end
end
