require 'image_processing/mini_magick'

class ImageUploader < Shrine
  plugin :store_dimensions
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :processing
  plugin :delete_raw
  plugin :pretty_location

  Attacher.validate do
    validate_mime_type_inclusion %w[image/jpeg image/png image/gif], message: "falscher MIME-Typ"
  end

  process(:store) do |io, context|
    original = io.download
    pipeline = ImageProcessing::MiniMagick.source(original)
    size_405 = pipeline.resize_to_limit!(405,270)
    original.close!
    File.open(size_405, "rb")
  end
end
