class LectureHomeAttachmentUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024 # 10 MB

  plugin :determine_mime_type, analyzer: :marcel
  plugin :restore_cached_data
  plugin :remove_attachment
  plugin :validation_helpers

  Attacher.validate do
    validate_min_size 1
    validate_max_size MAX_SIZE
    validate_mime_type_inclusion(
      ["application/pdf"],
      message: I18n.t("admin.lecture.home_attachment_must_be_pdf")
    )
  end
end
