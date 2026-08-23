module Mampfsearch
  class IngestionService
    def self.transcribe(medium)
      new(medium).transcribe
    end

    def initialize(medium)
      @medium = medium
    end

    def transcribe
      return unless @medium.transcribable?

      video_token = TranscriptionToken.generate(
        medium_id: @medium.id,
        purpose: :video,
        ttl: TranscriptionToken::VIDEO_TTL
      )
      transcript_token = TranscriptionToken.generate(
        medium_id: @medium.id,
        purpose: :transcript,
        ttl: TranscriptionToken::TRANSCRIPT_TTL
      )

      routes = Rails.application.routes.url_helpers
      video_stream_path = routes.transcription_stream_video_medium_path(@medium)
      transcript_upload_path = routes.add_transcript_path(@medium)

      video_url = "#{base_url}#{video_stream_path}?token=#{ERB::Util.url_encode(video_token)}"
      transcript_upload_url = "#{base_url}#{transcript_upload_path}?" \
                              "token=#{ERB::Util.url_encode(transcript_token)}"

      hierarchy = resolve_teachable_hierarchy

      SearchClient.instance.transcribe_lesson(
        media_rails_id: @medium.id,
        lesson_rails_id: hierarchy[:lesson_rails_id],
        lecture_rails_id: hierarchy[:lecture_rails_id],
        course_rails_id: hierarchy[:course_rails_id],
        video_url: video_url,
        transcript_upload_url: transcript_upload_url
      )
    end

    private

      def base_url
        host = ENV.fetch("URL_HOST")
        protocol = Rails.application.config.force_ssl ? "https" : "http"
        "#{protocol}://#{host}"
      end

      def resolve_teachable_hierarchy
        lesson = nil
        lecture = nil
        course = nil

        case @medium.teachable
        when Lesson
          lesson = @medium.teachable
          lecture = lesson.lecture
          course = lecture&.course
        when Talk
          lecture = @medium.teachable.lecture
          course = lecture&.course
        when Lecture
          lecture = @medium.teachable
          course = lecture.course
        when Course
          course = @medium.teachable
        end

        {
          lesson_rails_id: lesson&.id,
          lecture_rails_id: lecture&.id,
          course_rails_id: course&.id
        }
      end
  end
end
