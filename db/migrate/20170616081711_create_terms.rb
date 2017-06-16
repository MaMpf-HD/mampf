class CreateTerms < ActiveRecord::Migration[5.1]
  def change
    create_table :terms do |t|
      t.integer :year
      t.string :type

      t.timestamps
    end
  end
end
