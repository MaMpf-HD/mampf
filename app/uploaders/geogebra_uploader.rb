require "image_processing/mini_magick"
require "zip"

# GeogebraUploader class
# used for storing geogebra files
class GeogebraUploader < Shrine
  ARCHIVE_MIME_TYPE = "application/zip".freeze
  MAX_SIZE = 1 * 1024 * 1024
  MAX_THUMBNAIL_SIZE = 10 * 1024 * 1024
  MAX_THUMBNAIL_DIMENSIONS = [4096, 4096].freeze
  REQUIRED_ENTRY = "geogebra.xml".freeze
  THUMBNAIL_ENTRY = "geogebra_thumbnail.png".freeze

  plugin :upload_endpoint, max_size: MAX_SIZE
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :derivatives

  def self.filename_for(uploaded_file)
    uploaded_file.metadata["filename"].to_s
  end

  def self.extension_for(uploaded_file)
    File.extname(filename_for(uploaded_file))
  end

  def self.detected_mime_type_for(uploaded_file)
    uploaded_file.metadata["mime_type"]
  end

  def self.wrong_file_type_error(uploaded_file)
    I18n.t("submission.wrong_file_type",
           file_type: extension_for(uploaded_file),
           accepted_file_type: ".ggb")
  end

  def self.wrong_mime_type_error(uploaded_file)
    I18n.t("submission.wrong_mime_type",
           mime_type: detected_mime_type_for(uploaded_file),
           accepted_mime_types: ARCHIVE_MIME_TYPE)
  end

  def self.validation_error(uploaded_file)
    return wrong_file_type_error(uploaded_file) if extension_for(uploaded_file) != ".ggb"
    if detected_mime_type_for(uploaded_file) != ARCHIVE_MIME_TYPE
      return wrong_mime_type_error(uploaded_file)
    end

    inspection = inspect_archive(uploaded_file)
    return if inspection[:error].nil?
    return I18n.t("package.too_big") if inspection[:error] == :thumbnail_too_big

    I18n.t("geogebra.invalid_archive")
  end

  def self.inspect_archive(uploaded_file)
    Shrine.with_file(uploaded_file) do |file|
      Zip::File.open(file.path) do |zip_file|
        required_entry = zip_file.find_entry(REQUIRED_ENTRY)
        return { error: :invalid_archive } if required_entry.nil? || required_entry.directory?

        thumbnail_entry = zip_file.find_entry(THUMBNAIL_ENTRY)
        return { error: :invalid_archive } if thumbnail_entry&.directory?
        if thumbnail_entry && thumbnail_entry.size.to_i > MAX_THUMBNAIL_SIZE
          return { error: :thumbnail_too_big }
        end

        {}
      end
    end
  rescue Zip::Error, Errno::ENOENT, IOError
    { error: :invalid_archive }
  end

  def self.build_screenshot_derivative(original)
    Shrine.with_file(original) do |file|
      Zip::File.open(file.path) do |zip_file|
        thumbnail_entry = zip_file.find_entry(THUMBNAIL_ENTRY)
        return if thumbnail_entry.nil? || thumbnail_entry.directory?
        return if thumbnail_entry.size.to_i > MAX_THUMBNAIL_SIZE

        Tempfile.create(["geogebra-thumbnail", ".png"]) do |thumbnail_file|
          thumbnail_file.binmode
          thumbnail_entry.get_input_stream do |input_stream|
            IO.copy_stream(input_stream, thumbnail_file)
          end
          thumbnail_file.rewind

          derivative = validated_thumbnail_file(thumbnail_file.path)
          return derivative if derivative
        end
      end
    end
  rescue Zip::Error, MiniMagick::Error, MiniMagick::Invalid,
         Errno::ENOENT, IOError, ArgumentError
    nil
  end

  def self.validated_thumbnail_file(path)
    image = MiniMagick::Image.open(path)
    width, height = image.dimensions
    mime_type = Marcel::MimeType.for(Pathname.new(path), name: THUMBNAIL_ENTRY)

    return unless mime_type == "image/png"
    return if width > MAX_THUMBNAIL_DIMENSIONS[0] ||
              height > MAX_THUMBNAIL_DIMENSIONS[1]

    Tempfile.new(["geogebra-thumbnail", ".png"]).tap do |thumbnail_file|
      thumbnail_file.binmode
      File.open(path, "rb") do |input_stream|
        IO.copy_stream(input_stream, thumbnail_file)
      end
      thumbnail_file.rewind
    end
  end

  Attacher.validate do
    validate_max_size MAX_SIZE, message: I18n.t("package.too_big")

    error = GeogebraUploader.validation_error(file)
    errors << error if error
  end

  # extract a screenshot from the ggb file and store it beside the ggb file
  Attacher.derivatives_processor do |original|
    screenshot = GeogebraUploader.build_screenshot_derivative(original)
    screenshot ? { screenshot: screenshot } : {}
  end
end
