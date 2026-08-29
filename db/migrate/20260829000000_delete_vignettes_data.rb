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
    # chapters and forum hanging off it -- go with it. A course that was there
    # to carry such a lecture and now carries none goes too; one that also
    # holds a real lecture stays, with that lecture.
    def delete_vignette_lectures!
      lectures = Lecture.where(sort: "vignettes")
      course_ids = lectures.distinct.pluck(:course_id)
      say("destroying #{lectures.count} lecture(s) of sort vignettes")
      lectures.find_each(&:destroy!)

      # Media are not destroyed with their course (see Course#media), so a
      # course that carries some of its own is kept rather than turned into
      # media pointing at nothing.
      empty = Course.where(id: course_ids).where.missing(:lectures).where.missing(:media)
      kept = Course.where(id: course_ids).where.missing(:lectures).where.associated(:media)
      say("keeping #{kept.count} course(s) that carry media of their own") if kept.any?
      say("destroying #{empty.count} course(s) left without a lecture")
      empty.find_each(&:destroy!)
    end

    # Deleting the rich texts alone would leave the uploaded files behind, and
    # the variants of those files behind that: an original handed to #purge
    # passes its variants to a background job a migration cannot count on.
    #
    # The rows go by delete_all rather than by purge, because purging an
    # attachment touches the record it hangs on -- here a rich text naming a
    # vignette class this branch deletes, which no longer resolves. Only the
    # blobs are destroyed through the model, for the files behind them.
    def purge_trix_attachments
      rich_text_ids = select_values(<<~SQL.squish)
        SELECT id FROM action_text_rich_texts WHERE record_type LIKE 'Vignettes::%'
      SQL
      return if rich_text_ids.empty?

      embeds = ActiveStorage::Attachment.where(record_type: "ActionText::RichText",
                                               record_id: rich_text_ids)
      blob_ids = embeds.pluck(:blob_id)
      variants = ActiveStorage::VariantRecord.where(blob_id: blob_ids)
      variant_images = ActiveStorage::Attachment
                       .where(record_type: "ActiveStorage::VariantRecord",
                              record_id: variants.select(:id))
      blob_ids += variant_images.pluck(:blob_id)

      variant_images.delete_all
      variants.delete_all
      embeds.delete_all
      ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge)
    end
end
