class DeleteVignettesData < ActiveRecord::Migration[8.0]
  # Emptied by hand, and in this order. No foreign key between these tables
  # cascades (see the add_foreign_key lines in db/schema.rb), so a parent whose
  # children are still there refuses to go; and the models cannot help, because
  # the next migration drops vignettes_completion_messages and this branch
  # deletes its model with it.
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
    delete_vignette_lectures!
  end

  # Nothing to undo: the rows are gone either way, and rolling back is about
  # getting the schema back.
  def down
  end

  private

    # A lecture of the "vignettes" sort was never anything but a container for
    # one questionnaire, and the sort no longer exists. Destroyed through the
    # model, so that the eleven tables pointing at a lecture -- and the media,
    # chapters and forum hanging off it -- go with it.
    def delete_vignette_lectures!
      lectures = Lecture.where(sort: "vignettes")
      say("destroying #{lectures.count} lecture(s) of sort vignettes")
      lectures.find_each(&:destroy!)
    end

    # Deleting the rich texts alone would leave the uploaded files behind. The
    # variants go first and by hand: destroying an original hands its variants
    # to a background job, and a migration cannot count on one ever running.
    def purge_trix_attachments
      rich_text_ids = select_values(<<~SQL.squish)
        SELECT id FROM action_text_rich_texts WHERE record_type LIKE 'Vignettes::%'
      SQL
      return if rich_text_ids.empty?

      ActiveStorage::Attachment.where(record_type: "ActionText::RichText",
                                      record_id: rich_text_ids).find_each do |attachment|
        attachment.blob.variant_records.each { |variant| variant.image.purge }
        attachment.purge
      end
    end
end
