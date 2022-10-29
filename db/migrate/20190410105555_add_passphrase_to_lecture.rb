class AddPassphraseToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :passphrase, :text
  end
end
