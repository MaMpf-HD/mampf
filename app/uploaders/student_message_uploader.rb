# Uploader for attachments of messages to registered students
# (e.g. a course program sent around before the semester starts).
class StudentMessageUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024 # 10 MB

  # shrine plugins
  # (no default_storage override: attachments live in the regular media
  # cache/store, like the uploads of PdfUploader & co.)
  plugin :determine_mime_type, analyzer: :marcel
  plugin :restore_cached_data
  plugin :validation_helpers

  Attacher.validate do
    validate_min_size 1
    validate_max_size MAX_SIZE
    # restricted to PDF for now (mime type is content-sniffed via marcel,
    # not taken from the file extension)
    validate_mime_type_inclusion(
      ["application/pdf"],
      message: I18n.t("registration.student_message.attachment_must_be_pdf")
    )
  end
end
