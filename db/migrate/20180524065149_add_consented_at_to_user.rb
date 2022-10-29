class AddConsentedAtToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :consented_at, :timestamp
  end
end
