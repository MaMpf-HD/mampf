class CreateProbes < ActiveRecord::Migration[6.0]
  def change
    create_table :probes do |t|
      t.integer :question_id
      t.integer :quiz_id
      t.boolean :correct
      t.text :session_id

      t.timestamps
    end
  end
end
