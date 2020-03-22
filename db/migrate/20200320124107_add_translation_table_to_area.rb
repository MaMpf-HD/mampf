class AddTranslationTableToArea < ActiveRecord::Migration[6.0]
  def self.up
    Area.create_translation_table!({
      name: :text }, {
      migrate_data: true,
      remove_source_columns: true
    })
  end

  def self.down
    Area.drop_translation_table! migrate_data: true
  end
end

