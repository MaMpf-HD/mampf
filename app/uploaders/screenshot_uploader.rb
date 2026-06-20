require "image_processing/mini_magick"
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

  Attacher.validate do
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
    magick = ImageProcessing::MiniMagick.source(original)
    { normalized: magick.resize_to_limit!(405, 270) }
  end
end
