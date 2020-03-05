# GeogebraUploader class
# used for storing geogebra files
class GeogebraUploader < Shrine
  plugin :determine_mime_type
  plugin :validation_helpers

  Attacher.validate do
    validate_mime_type_inclusion %w[application/zip],
                                 message: 'falscher MIME-Typ'
  end
end