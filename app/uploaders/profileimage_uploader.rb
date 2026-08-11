require "image_processing/vips"
# ProfileimageUploader class
# used for storing profile images
class ProfileimageUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024
  MAX_DIMENSIONS = [4096, 4096].freeze
  ACCEPTED_MIME_TYPES = ["image/jpeg", "image/png", "image/gif"].freeze

  # shrine plugins
  plugin :upload_endpoint, max_size: MAX_SIZE
  plugin :store_dimensions
  plugin :determine_mime_type, analyzer: :marcel
  plugin :restore_cached_data
  plugin :validation_helpers
  plugin :pretty_location
  plugin :derivatives

  Attacher.prepend(MalwareScannableAttacher)

  Attacher.validate do
    MalwareScanGate.validate_cached_file!(self)

    validate_mime_type_inclusion(
      ACCEPTED_MIME_TYPES,
      message: I18n.t("submission.wrong_mime_type",
                      mime_type: file&.mime_type,
                      accepted_mime_types: ACCEPTED_MIME_TYPES.join(", "))
    )
    validate_max_size MAX_SIZE, message: I18n.t("package.too_big")
    validate_max_dimensions MAX_DIMENSIONS,
                            message: I18n.t("image.too_large_dimensions",
                                            max_width: MAX_DIMENSIONS[0],
                                            max_height: MAX_DIMENSIONS[1])
  end

  # store a resized version of the screenshot
  Attacher.derivatives_processor do |original|
    pipeline = ImageProcessing::Vips.source(original)
    { normalized: pipeline.resize_to_limit!(512, 512) }
  end
end
