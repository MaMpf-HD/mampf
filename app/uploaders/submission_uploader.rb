# SubmissionUploader Class
class SubmissionUploader < Shrine
  MAX_SIZE = 20 * 1024 * 1024

  # shrine plugins
  plugin :determine_mime_type, analyzer: :marcel
  plugin :upload_endpoint, max_size: MAX_SIZE
  plugin :default_storage, cache: :submission_cache, store: :submission_store
  plugin :restore_cached_data
  plugin :validation_helpers

  def self.extension_for(filename)
    name = filename.to_s

    return ".tar.gz" if name.end_with?(".tar.gz")

    File.extname(name)
  end

  def self.allowed_extension?(filename)
    extension_for(filename).in?(Assignment.accepted_file_types)
  end

  def self.accepted_extension_list
    Assignment.accepted_file_types.join(", ")
  end

  def self.accepted_mime_types_for(filename)
    Assignment.accepted_mime_types[extension_for(filename)] || []
  end

  def self.allowed_mime_type?(filename:, mime_type:)
    accepted_mime_types = accepted_mime_types_for(filename)

    return false if accepted_mime_types.empty?

    if accepted_mime_types.include?("text/*")
      return mime_type == "application/octet-stream" ||
             mime_type.to_s.start_with?("text/")
    end

    mime_type.in?(accepted_mime_types)
  end

  class Attacher
    def upload(io, storage = store_key, **)
      if io && storage.to_sym == cache_key && !io.is_a?(Shrine::UploadedFile)
        return MalwareScanGate.upload_for_attacher(self, io, storage, **)
      end

      super
    end

    def promote(storage: store_key, **options)
      MalwareScanGate.ensure_promotable!(file)
      super
    end
  end

  Attacher.validate do
    MalwareScanGate.validate_cached_file!(self)

    # Reject empty file uploads
    # at least 1 byte
    validate_min_size 1, message: I18n.t("submission.upload_failure_empty_file")
    validate_max_size MAX_SIZE, message: I18n.t("package.too_big")

    filename = file.metadata["filename"]
    extension = SubmissionUploader.extension_for(filename)

    unless SubmissionUploader.allowed_extension?(filename)
      errors << I18n.t("submission.wrong_file_type",
                       file_type: extension,
                       accepted_file_type: SubmissionUploader.accepted_extension_list)
      next
    end

    unless SubmissionUploader.allowed_mime_type?(filename: filename,
                                                 mime_type: file.metadata["mime_type"])
      errors << I18n.t("submission.wrong_mime_type",
                       mime_type: file.metadata["mime_type"],
                       accepted_mime_types:
                         SubmissionUploader.accepted_mime_types_for(filename).join(", "))
    end
  end
end
