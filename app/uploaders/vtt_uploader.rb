# VttUploader class
class VttUploader < Shrine
  plugin :pretty_location
  plugin :determine_mime_type
end