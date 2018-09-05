require "streamio-ffmpeg"

class VideoUploader < Shrine
  plugin :add_metadata
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :pretty_location  

  add_metadata do |io, context|
    movie = Shrine.with_file(io) { |file| FFMPEG::Movie.new(file.path) }

    { "duration"   => movie.duration,
      "bitrate"    => movie.bitrate,
      "resolution" => movie.resolution,
      "frame_rate" => movie.frame_rate }
  end

  Attacher.validate do
    validate_mime_type_inclusion %w[video/mp4 video/webm video/ogg], message: "wrong type"
  end
end
