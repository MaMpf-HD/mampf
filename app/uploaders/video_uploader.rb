require 'streamio-ffmpeg'

# VideoUploader class
class VideoUploader < Shrine
  # shrine plugins
  plugin :add_metadata
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :pretty_location

  # add metadata to uploaded video: duration, bitrate, resolution, framerate
  add_metadata do |io, context|
    movie = Shrine.with_file(io) { |file| FFMPEG::Movie.new(file.path) }

    { 'duration'   => movie.duration,
      'bitrate'    => movie.bitrate,
      'resolution' => movie.resolution,
      'frame_rate' => movie.frame_rate }
  end

  Attacher.validate do
    validate_mime_type_inclusion %w[video/mp4], message: 'wrong type'
  end
end
