require "rails_helper"

RSpec.describe Mampfsearch::IngestionService, :mampfsearch do
  let(:search_client) { instance_double(SearchClient) }

  before do
    allow(SearchClient).to receive(:instance).and_return(search_client)
  end

  describe ".transcribe" do
    it "returns nil when medium is not transcribable (no video)" do
      medium = FactoryBot.create(:valid_medium, video: nil)
      expect(search_client).not_to receive(:transcribe_lesson)

      result = described_class.transcribe(medium)
      expect(result).to be_nil
    end

    it "transcribes a lesson medium resolving full teachable hierarchy and signed URLs" do
      medium = FactoryBot.create(:lesson_medium, :with_video)
      lesson = medium.teachable
      lecture = lesson.lecture
      course = lecture.course

      expect(search_client).to receive(:transcribe_lesson).with(
        hash_including(
          media_rails_id: medium.id,
          lesson_rails_id: lesson.id,
          lecture_rails_id: lecture.id,
          course_rails_id: course.id,
          video_url: a_string_matching(%r{/media/#{medium.id}/video/transcription_stream\?token=}),
          transcript_upload_url: a_string_matching(%r{/api/webhooks/media/#{medium.id}/transcripts\?token=})
        )
      )

      described_class.transcribe(medium)
    end

    it "transcribes a lecture medium resolving lecture and course" do
      medium = FactoryBot.create(:lecture_medium, :with_video)
      lecture = medium.teachable
      course = lecture.course

      expect(search_client).to receive(:transcribe_lesson).with(
        hash_including(
          media_rails_id: medium.id,
          lesson_rails_id: nil,
          lecture_rails_id: lecture.id,
          course_rails_id: course.id
        )
      )

      described_class.transcribe(medium)
    end

    it "transcribes a course medium resolving course" do
      medium = FactoryBot.create(:course_medium, :with_video)
      course = medium.teachable

      expect(search_client).to receive(:transcribe_lesson).with(
        hash_including(
          media_rails_id: medium.id,
          lesson_rails_id: nil,
          lecture_rails_id: nil,
          course_rails_id: course.id
        )
      )

      described_class.transcribe(medium)
    end

    it "transcribes a talk medium resolving lecture and course" do
      medium = FactoryBot.create(:talk_medium, :with_video)
      talk = medium.teachable
      lecture = talk.lecture
      course = lecture.course

      expect(search_client).to receive(:transcribe_lesson).with(
        hash_including(
          media_rails_id: medium.id,
          lesson_rails_id: nil,
          lecture_rails_id: lecture.id,
          course_rails_id: course.id
        )
      )

      described_class.transcribe(medium)
    end
  end
end
