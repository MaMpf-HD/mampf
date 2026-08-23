class TranscriptUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024
  MAX_CUES = 20_000
  ACCEPTED_MIME_TYPES = ["text/vtt"].freeze
  # Cue timing lines look like "00:00:11.120 --> 00:00:42.771" with an optional
  # trailing set of cue settings. Both minutes- and hours-based timestamps are
  # valid WebVTT.
  TIMESTAMP_LINE = /\A(?:\d{1,2}:)?\d{2}:\d{2}\.\d{3} --> (?:\d{1,2}:)?\d{2}:\d{2}\.\d{3}(?:\s+.*)?\z/

  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  plugin :pretty_location

  Attacher.validate do
    extension = file&.extension

    validate_mime_type_inclusion(
      ACCEPTED_MIME_TYPES,
      message: I18n.t("submission.wrong_mime_type",
                      mime_type: file&.mime_type,
                      accepted_mime_types: ACCEPTED_MIME_TYPES.join(", "))
    )
    validate_extension_inclusion ["vtt"],
                                message: I18n.t("submission.wrong_file_type",
                                                file_type: extension ? ".#{extension}" : "",
                                                accepted_file_type: ".vtt")
    validate_max_size MAX_SIZE, message: I18n.t("package.too_big")

    error = TranscriptUploader.structure_error(file)
    errors << error if error
  end

  # Content-level validation: the file must be valid UTF-8, start with a
  # WEBVTT header, and only contain well-formed, bounded cue timings.
  def self.structure_error(uploaded_file)
    Shrine.with_file(uploaded_file) do |file|
      content = file.read
      content = content.dup.force_encoding(Encoding::UTF_8)
      return I18n.t("submission.invalid_transcript") unless content.valid_encoding?

      lines = content.sub(/\A\uFEFF/, "").lines
      return I18n.t("submission.invalid_transcript") unless lines.first.to_s.lstrip.start_with?("WEBVTT")

      cue_count = 0
      lines.each do |line|
        next unless line.include?("-->")

        return I18n.t("submission.invalid_transcript") unless TIMESTAMP_LINE.match?(line.strip)

        cue_count += 1
        if cue_count > MAX_CUES
          return I18n.t("submission.transcript_too_many_cues", max_cues: MAX_CUES)
        end
      end
      nil
    end
  rescue StandardError
    I18n.t("submission.invalid_transcript")
  end
end
