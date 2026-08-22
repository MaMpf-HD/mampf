class DeleteVignettesData < ActiveRecord::Migration[8.0]
  # Child tables first: the deletions run as plain SQL, so no dependent
  # callback clears the referencing rows for us.
  TABLES = [
    "vignettes_answers_options",
    "vignettes_slide_statistics",
    "vignettes_answers",
    "vignettes_user_answers",
    "vignettes_options",
    "vignettes_questions",
    "vignettes_info_slides_slides",
    "vignettes_info_slides",
    "vignettes_slides",
    "vignettes_completion_messages",
    "vignettes_questionnaires",
    "vignettes_codenames"
  ].freeze

  def up
    purge_trix_attachments
    execute("DELETE FROM action_text_rich_texts WHERE record_type LIKE 'Vignettes::%'")
    TABLES.each { |table| execute("DELETE FROM #{table}") }
    execute("UPDATE lectures SET sort = 'lecture' WHERE sort = 'vignettes'")
  end

  def down
    raise(ActiveRecord::IrreversibleMigration)
  end

  private

    # Deleting the rich texts alone would leave the uploaded files behind.
    def purge_trix_attachments
      rich_text_ids = select_values(<<~SQL.squish)
        SELECT id FROM action_text_rich_texts WHERE record_type LIKE 'Vignettes::%'
      SQL
      return if rich_text_ids.empty?

      ActiveStorage::Attachment.where(record_type: "ActionText::RichText",
                                      record_id: rich_text_ids)
                               .find_each(&:purge)
    end
end
