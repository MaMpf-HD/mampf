class AddTranslationTableToProgram < ActiveRecord::Migration[6.0]
  def self.up
    # We migrated from globalize to mobility in PR #609, therefore the method
    # create_translation_table! is not available anymore.
    #
    # Program.create_translation_table!({
    #                                     name: :text
    #                                   }, {
    #                                     migrate_data: true,
    #                                     remove_source_columns: true
    #                                   })
  end

  def self.down
    # Program.drop_translation_table! migrate_data: true
  end
end
