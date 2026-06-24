require "image_processing/vips"
# ScreenshotUploader class
# used for storing video thumbnails
class ScreenshotUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024
  MAX_DIMENSIONS = [4096, 4096].freeze

  # shrine plugins
  plugin :upload_endpoint, max_size: MAX_SIZE
  plugin :store_dimensions
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  plugin :pretty_location
  plugin :derivatives

  class Attacher
    def upload(io, storage = store_key, **options)
      if io && storage.to_sym == cache_key && !io.is_a?(Shrine::UploadedFile)
        return MalwareScanGate.upload_for_attacher(self, io, storage, **options)
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

    validate_mime_type_inclusion ["image/jpeg", "image/png", "image/gif"],
                                 message: "falscher MIME-Typ"
    validate_max_size MAX_SIZE, message: I18n.t("package.too_big")
    validate_max_dimensions MAX_DIMENSIONS,
                            message: I18n.t("image.too_large_dimensions",
                                            max_width: MAX_DIMENSIONS[0],
                                            max_height: MAX_DIMENSIONS[1])
  end

  # store a resized version of the screenshot
  Attacher.derivatives_processor do |original|
    pipeline = ImageProcessing::Vips.source(original)
    { normalized: pipeline.resize_to_limit!(405, 270) }
  end
end
