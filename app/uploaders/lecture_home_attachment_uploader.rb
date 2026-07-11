# Uploader for the optional PDF a teacher attaches to the lecture home page
# (e.g. a seminar/course program). Mirrors StudentMessageUploader: PDF-only,
# max 10 MB, stored in the regular media cache/store.
class LectureHomeAttachmentUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024 # 10 MB

  plugin :determine_mime_type, analyzer: :marcel
  plugin :restore_cached_data
  plugin :remove_attachment
  plugin :validation_helpers

  Attacher.validate do
    validate_min_size 1
    validate_max_size MAX_SIZE
    # restricted to PDF for now (mime type is content-sniffed via marcel,
    # not taken from the file extension)
    validate_mime_type_inclusion(
      ["application/pdf"],
      message: I18n.t("admin.lecture.home_attachment_must_be_pdf")
    )
  end
end
