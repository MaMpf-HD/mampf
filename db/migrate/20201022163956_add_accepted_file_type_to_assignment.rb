class AddAcceptedFileTypeToAssignment < ActiveRecord::Migration[6.0]
  def up
    add_column :assignments, :accepted_file_type, :text, default: '.pdf'
  end

  def down
    remove_column :assignments, :accepted_file_type, :text
  end
end
