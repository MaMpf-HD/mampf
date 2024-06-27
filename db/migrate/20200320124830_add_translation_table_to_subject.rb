# We migrated from globalize to mobility in PR #609. In mobility, the methods
# used here are not available anymore.
class AddTranslationTableToSubject < ActiveRecord::Migration[6.0]
  def self.up
    # Subject.create_translation_table!({
    #                                     name: :text
    #                                   }, {
    #                                     migrate_data: true,
    #                                     remove_source_columns: true
    #                                   })
  end

  def self.down
    # Subject.drop_translation_table! migrate_data: true
  end
end
