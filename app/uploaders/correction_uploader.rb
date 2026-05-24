require "image_processing/mini_magick"

# UserPdfUploader Class
class CorrectionUploader < Shrine
  TEXT_EXTENSIONS = [".cc", ".hh", ".m", ".txt"].freeze
  ZIP_EXTENSIONS = [".mlx", ".zip"].freeze
  ALLOWED_EXTENSIONS = (TEXT_EXTENSIONS + ZIP_EXTENSIONS + [".pdf"]).freeze
  ZIP_MIME_TYPES = ["application/zip", "application/x-zip",
                    "application/x-zip-compressed",
                    "application/octet-stream", "application/x-compress",
                    "application/x-compressed", "multipart/x-zip"].freeze

  # shrine plugins
  plugin :determine_mime_type, analyzer: :marcel
  plugin :upload_endpoint, max_size: 30 * 1024 * 1024 # 30 MB
  plugin :default_storage, cache: :submission_cache, store: :submission_store
  plugin :validation_helpers

  def self.allowed_extension?(filename)
    File.extname(filename.to_s).in?(ALLOWED_EXTENSIONS)
  end

  def self.allowed_mime_type?(filename:, mime_type:)
    extension = File.extname(filename.to_s)

    return mime_type == "application/pdf" if extension == ".pdf"
    return mime_type.in?(ZIP_MIME_TYPES) if extension.in?(ZIP_EXTENSIONS)

    if extension.in?([".cc", ".hh", ".m"])
      return mime_type == "application/octet-stream" ||
             mime_type.to_s.start_with?("text/")
    end
    if extension.in?(TEXT_EXTENSIONS)
      return mime_type == "application/octet-stream" ||
             mime_type.to_s.start_with?("text/")
    end

    false
  end

  def self.accepted_extension_list
    ALLOWED_EXTENSIONS.join(", ")
  end

  def self.accepted_mime_types_for(filename)
    extension = File.extname(filename.to_s)

    return ["application/pdf"] if extension == ".pdf"
    return ZIP_MIME_TYPES if extension.in?(ZIP_EXTENSIONS)
    return ["text/*", "application/octet-stream"] if extension.in?([".cc", ".hh", ".m"])
    return ["text/*", "application/octet-stream"] if extension == ".txt"

    []
  end

  Attacher.validate do
    # Reject empty file uploads
    # at least 1 byte
    validate_min_size 1, message: I18n.t("submission.upload_failure_empty_file")

    filename = file.metadata["filename"]
    extension = File.extname(filename.to_s)

    unless CorrectionUploader.allowed_extension?(filename)
      errors << I18n.t("submission.wrong_file_type",
                       file_type: extension,
                       accepted_file_type: CorrectionUploader.accepted_extension_list)
      next
    end

    unless CorrectionUploader.allowed_mime_type?(filename: filename,
                                                 mime_type: file.metadata["mime_type"])
      errors << I18n.t("submission.wrong_mime_type",
                       mime_type: file.metadata["mime_type"],
                       accepted_mime_types:
                         CorrectionUploader.accepted_mime_types_for(filename).join(", "))
    end
  end
end
