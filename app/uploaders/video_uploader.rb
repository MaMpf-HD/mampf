require "streamio-ffmpeg"

# VideoUploader class
class VideoUploader < Shrine
  MAX_SIZE = 4 * 1024 * 1024 * 1024
  WRONG_TYPE_MESSAGE = "wrong type".freeze

  # shrine plugins
  plugin :upload_endpoint, max_size: MAX_SIZE # 4 GB
  plugin :add_metadata
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  plugin :pretty_location
  plugin :refresh_metadata

  # add metadata to uploaded video: duration, bitrate, resolution, framerate
  add_metadata do |io, **options|
    if options[:action] != :upload
      movie = Shrine.with_file(io) { |file| FFMPEG::Movie.new(file.path) }

      { "duration" => movie.duration,
        "bitrate" => movie.bitrate,
        "resolution" => movie.resolution,
        "frame_rate" => movie.frame_rate }
    end
  end

  Attacher.validate do
    validate_mime_type_inclusion ["video/mp4"], message: WRONG_TYPE_MESSAGE
    validate_max_size MAX_SIZE,
                      message: I18n.t("package.too_big")
  end
end
