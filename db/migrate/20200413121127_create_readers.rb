class CreateReaders < ActiveRecord::Migration[6.0]
  def change
    create_table :readers do |t|
      t.integer :user_id
      t.integer :thread_id

      t.timestamps
    end
  end
end
