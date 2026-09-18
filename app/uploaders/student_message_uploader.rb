# Uploader for attachments of messages to students (e.g. a course program
# sent around before the semester starts).
class StudentMessageUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024 # 10 MB

  # shrine plugins
  # (no default_storage override: attachments live in the regular media
  # cache/store, like the uploads of PdfUploader & co.)
  plugin :determine_mime_type, analyzer: :marcel
  plugin :restore_cached_data
  plugin :validation_helpers

  # The attachment goes out to every address the sender picked, under
  # MaMpf's name: scanned like every other upload.
  Attacher.prepend(MalwareScannableAttacher)

  Attacher.validate do
    # Cached data handed in from outside - another record's, an unscanned
    # file's - is not an upload of this record.
    MalwareScanGate.validate_cached_file!(self)

    validate_min_size 1
    validate_max_size MAX_SIZE
    # restricted to PDF for now (mime type is content-sniffed via marcel,
    # not taken from the file extension)
    validate_mime_type_inclusion(
      ["application/pdf"],
      message: I18n.t("student_message.attachment_must_be_pdf")
    )
  end
end
