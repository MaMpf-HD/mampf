require "streamio-ffmpeg"

# VideoUploader class
class VideoUploader < Shrine
  # shrine plugins
  plugin :upload_endpoint, max_size: 4 * 1024 * 1024 * 1024 # 4 GB
  plugin :add_metadata
  plugin :determine_mime_type, analyzer: :file
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
    validate_mime_type_inclusion ["video/mp4"], message: "wrong type"
    validate_max_size 4 * 1024 * 1024 * 1024,
                      message: I18n.t("package.too_big")
  end
end
