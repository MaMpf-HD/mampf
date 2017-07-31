class DropStiTables < ActiveRecord::Migration[5.1]
  def up
     drop_table :erdbeere_assets
     drop_table :kaviar_assets
     drop_table :keks_assets
     drop_table :reste_assets
     drop_table :sesam_assets     
   end

   def down
     raise ActiveRecord::IrreversibleMigration
   end
end
