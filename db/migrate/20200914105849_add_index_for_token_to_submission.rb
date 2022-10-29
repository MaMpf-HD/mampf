class AddIndexForTokenToSubmission < ActiveRecord::Migration[6.0]
  def up
    add_index :submissions, :token, unique: true
  end

  def down
    remove_index :submissions, :token
  end
end
