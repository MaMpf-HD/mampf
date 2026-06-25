require "streamio-ffmpeg"

# VideoUploader class
class VideoUploader < Shrine
  MAX_SIZE = 4 * 1024 * 1024 * 1024
  # Upper bound (bytes) on what is streamed to clamd. Video is scanned over a
  # bounded prefix only: this is defense-in-depth against known malware near the
  # container start, NOT a full-file clean verdict (see MalwareScanGate and
  # docs/CLAMAV_UPLOAD_SCANNING.md in mampf-infra).
  SCAN_MAX_BYTES = 32 * 1024 * 1024
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

  Attacher.prepend(MalwareScannableAttacher)

  Attacher.validate do
    MalwareScanGate.validate_cached_file!(self)

    validate_mime_type_inclusion ["video/mp4"], message: WRONG_TYPE_MESSAGE
    validate_max_size MAX_SIZE,
                      message: I18n.t("package.too_big")
  end
end
