class AddTranslationTableToDivision < ActiveRecord::Migration[6.0]
  def self.up
    Division.create_translation_table!({
                                         name: :text
                                       }, {
                                         migrate_data: true,
                                         remove_source_columns: true
                                       })
  end

  def self.down
    Division.drop_translation_table! migrate_data: true
  end
end
