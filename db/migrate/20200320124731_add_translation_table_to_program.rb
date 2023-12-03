class AddTranslationTableToProgram < ActiveRecord::Migration[6.0]
  def self.up
    Program.create_translation_table!({
      name: :text }, {
      migrate_data: true,
      remove_source_columns: true
    })
  end

  def self.down
    Program.drop_translation_table! migrate_data: true
  end
end
