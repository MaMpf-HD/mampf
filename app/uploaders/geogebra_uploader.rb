require "zip"

# GeogebraUploader class
# used for storing geogebra files
class GeogebraUploader < Shrine
  plugin :upload_endpoint
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :derivatives

  Attacher.validate do
    validate_mime_type_inclusion %w[application/zip],
                                 message: "falscher MIME-Typ"
  end

  # extract a screenshot from the ggb file and store it beside the ggb file
  Attacher.derivatives_processor do |original|
    unzipped = ""
    Zip::File.open(original) do |zip_file|
      destination = Dir.mktmpdir("geogebra")
      zipped = zip_file.find { |f| f.name == "geogebra_thumbnail.png" }
      unzipped = File.join(destination, "geogebra_thumbnail.png")
      zip_file.extract(zipped, unzipped)
    end
    { screenshot: File.open(unzipped) }
  end
end
