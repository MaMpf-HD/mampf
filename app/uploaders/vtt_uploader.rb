# VttUploader class
class VttUploader < Shrine
  MAX_SIZE = 1 * 1024 * 1024

  plugin :pretty_location
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers

  Attacher.validate do
    validate_mime_type_inclusion ["text/vtt"]
    validate_extension_inclusion ["vtt"]
    validate_max_size MAX_SIZE, message: I18n.t("package.too_big")
  end
end
