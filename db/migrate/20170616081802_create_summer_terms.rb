class CreateSummerTerms < ActiveRecord::Migration[5.1]
  def change
    create_table :summer_terms do |t|

      t.timestamps
    end
  end
end
