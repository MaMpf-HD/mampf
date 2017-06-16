class CreateWinterTerms < ActiveRecord::Migration[5.1]
  def change
    create_table :winter_terms do |t|

      t.timestamps
    end
  end
end
