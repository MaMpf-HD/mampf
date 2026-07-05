# Uploader for attachments of messages to registered students
# (e.g. a course program sent around before the semester starts).
class StudentMessageUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024 # 10 MB

  # shrine plugins
  plugin :determine_mime_type, analyzer: :marcel
  plugin :default_storage, cache: :submission_cache, store: :submission_store
  plugin :restore_cached_data
  plugin :validation_helpers

  Attacher.validate do
    validate_min_size 1
    validate_max_size MAX_SIZE
  end
end
