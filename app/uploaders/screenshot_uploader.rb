require 'image_processing/mini_magick'
# ScreenshotUploader class
# used for storing video thumbnails
class ScreenshotUploader < Shrine
  # shrine plugins
  plugin :store_dimensions
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :processing
  plugin :delete_raw
  plugin :pretty_location

  Attacher.validate do
    validate_mime_type_inclusion %w[image/jpeg image/png image/gif],
                                 message: 'falscher MIME-Typ'
  end

  # store a resized version of the screenshot
  process(:store) do |io, context|
    original = io.download
    pipeline = ImageProcessing::MiniMagick.source(original)
    size405 = pipeline.resize_to_limit!(405, 270)
    original.close!
    File.open(size405, 'rb')
  end
end
