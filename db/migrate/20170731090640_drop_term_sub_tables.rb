class DropTermSubTables < ActiveRecord::Migration[5.1]
  def up
     drop_table :summer_terms
     drop_table :winter_terms  
   end

   def down
     raise ActiveRecord::IrreversibleMigration
   end
end
