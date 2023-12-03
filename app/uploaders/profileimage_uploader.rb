require 'image_processing/mini_magick'
# ProfileimageUploader class
# used for storing profile images
class ProfileimageUploader < Shrine
  # shrine plugins
  plugin :upload_endpoint
  plugin :store_dimensions
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :pretty_location
  plugin :derivatives

  Attacher.validate do
    validate_mime_type_inclusion %w[image/jpeg image/png image/gif],
                                 message: 'falscher MIME-Typ'
  end

  # store a resized version of the screenshot
  Attacher.derivatives_processor do |original|
    magick = ImageProcessing::MiniMagick.source(original)
    { normalized: magick.resize_to_limit!(512, 512) }
  end
end
