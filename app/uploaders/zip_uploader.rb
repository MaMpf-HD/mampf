# ZipUploader Class
class ZipUploader < Shrine
  # shrine plugins
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  plugin :upload_endpoint, max_size: 1024 * 1024 * 1024 #  1 GB
  plugin :default_storage, cache: :submission_cache, store: :submission_store

  Attacher.validate do
    validate_mime_type_inclusion %w[application/zip],
                                 message:
                                    I18n.t("package.no_zip")
    # maximum size of 1 GB
    validate_max_size 1024 * 1024 * 1024,
                      message: I18n.t("package.too_big")
  end
end
