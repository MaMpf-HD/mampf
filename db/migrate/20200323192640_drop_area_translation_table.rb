class DropAreaTranslationTable < ActiveRecord::Migration[6.0]
  def change
  	drop_table :area_translations
  end
end
