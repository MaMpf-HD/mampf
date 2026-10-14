require "rails_helper"

RSpec.describe(MampfsearchSyncJob, :mampfsearch, type: :job) do
  let(:search_client) { instance_double(SearchClient) }

  before do
    allow(SearchClient).to receive(:instance).and_return(search_client)
    allow(search_client).to receive(:list_media_versions).and_return({})
    allow(search_client).to receive(:list_media_hierarchies).and_return(nil)
  end

  describe "#recover_stuck_jobs" do
    it "recovers stuck job with attempts < MAX to failed_temporarily and increments attempts" do
      stuck = FactoryBot.create(:valid_medium, :with_video,
                                transcription_status: :queued,
                                transcription_attempts: 1,
                                transcription_requested_at: 3.hours.ago)

      described_class.perform_now

      stuck.reload
      expect(stuck.transcription_attempts).to eq(2)
      expect(stuck.transcription_status).to eq("failed_temporarily")
      expect(stuck.transcription_error).to include("timed out")
    end

    it "marks stuck job with attempts >= MAX as failed_permanently and logs error" do
      stuck = FactoryBot.create(:valid_medium, :with_video,
                                transcription_status: :queued,
                                transcription_attempts: 3,
                                transcription_requested_at: 3.hours.ago)

      expect(Rails.logger).to receive(:error).with(/permanently timed out/)

      described_class.perform_now

      stuck.reload
      expect(stuck.transcription_status).to eq("failed_permanently")
    end
  end

  describe "#feed_next_batch" do
    before do
      Medium.delete_all
      allow(MampfsearchIngestJob).to receive(:perform_later)
    end

    it "enqueues next batch of un-transcribed media" do
      FactoryBot.create_list(:valid_medium, 3, :with_video,
                             transcription_status: :not_transcribed)

      RSpec::Mocks.space.proxy_for(MampfsearchIngestJob).reset

      expect(MampfsearchIngestJob).to receive(:perform_later).exactly(3).times

      described_class.perform_now

      expect(Medium.where(transcription_status: :queued).count).to eq(3)
    end

    it "does not enqueue the same media again when sync runs twice" do
      FactoryBot.create_list(:valid_medium, 3, :with_video,
                             transcription_status: :not_transcribed)

      expect(MampfsearchIngestJob).to receive(:perform_later).exactly(3).times

      described_class.perform_now
      described_class.perform_now
    end

    it "caps enqueuing when in-flight queued jobs approach threshold" do
      FactoryBot.create_list(:valid_medium, 12, :with_video,
                             transcription_status: :queued,
                             transcription_requested_at: 5.minutes.ago)

      FactoryBot.create_list(:valid_medium, 5, :with_video,
                             transcription_status: :not_transcribed)

      RSpec::Mocks.space.proxy_for(MampfsearchIngestJob).reset

      # 15 max in-flight - 12 existing = 3 batch size
      expect(MampfsearchIngestJob).to receive(:perform_later).exactly(3).times

      described_class.perform_now
    end
  end

  describe "#reconcile_search_index" do
    it "queues metadata sync for an indexed video with a different hierarchy" do
      medium = FactoryBot.create(:lesson_medium, :with_video,
                                 transcription_status: :completed)
      hierarchy = Mampfsearch::Hierarchy.for(medium)
      allow(search_client).to receive(:list_media_versions)
        .and_return(medium.id => medium.video_fingerprint)
      allow(search_client).to receive(:list_media_hierarchies)
        .and_return(medium.id => [hierarchy[:course_rails_id], 0,
                                  hierarchy[:lesson_rails_id],
                                  hierarchy[:course_rails_id],
                                  hierarchy[:lecture_rails_id]])

      expect(MampfsearchMetadataSyncJob).to receive(:perform_later).with(medium.id)
      expect(MampfsearchIngestJob).not_to receive(:perform_later)

      described_class.perform_now
    end

    it "skips metadata sync when the indexed hierarchy matches" do
      medium = FactoryBot.create(:lesson_medium, :with_video,
                                 transcription_status: :completed)
      hierarchy = Mampfsearch::Hierarchy.for(medium)
      allow(search_client).to receive(:list_media_versions)
        .and_return(medium.id => medium.video_fingerprint)
      allow(search_client).to receive(:list_media_hierarchies)
        .and_return(medium.id => [hierarchy[:course_rails_id],
                                  hierarchy[:lecture_rails_id],
                                  hierarchy[:lesson_rails_id],
                                  hierarchy[:course_rails_id],
                                  hierarchy[:lecture_rails_id]])

      expect(MampfsearchMetadataSyncJob).not_to receive(:perform_later)
      described_class.perform_now
    end

    it "repairs a stale parent link even if the medium IDs match" do
      medium = FactoryBot.create(:lesson_medium, :with_video,
                                 transcription_status: :completed)
      hierarchy = Mampfsearch::Hierarchy.for(medium)
      allow(search_client).to receive(:list_media_versions)
        .and_return(medium.id => medium.video_fingerprint)
      allow(search_client).to receive(:list_media_hierarchies)
        .and_return(medium.id => [hierarchy[:course_rails_id],
                                  hierarchy[:lecture_rails_id],
                                  hierarchy[:lesson_rails_id],
                                  hierarchy[:course_rails_id], 0])

      expect(MampfsearchMetadataSyncJob).to receive(:perform_later).with(medium.id)
      described_class.perform_now
    end

    it "invalidates an older version and re-ingests the completed video" do
      medium = FactoryBot.create(:valid_medium, :with_video,
                                 transcription_status: :completed)
      allow(search_client).to receive(:list_media_versions)
        .and_return(medium.id => "old-version")
      expect(search_client).to receive(:invalidate_media)
        .with(medium.id, expected_video_version: "old-version")
        .and_return(true)
      expect(MampfsearchIngestJob).to receive(:perform_later).with(medium.id)

      described_class.perform_now

      expect(medium.reload.transcription_status).to eq("completed")
    end

    it "does not re-ingest if the version changed before invalidation" do
      medium = FactoryBot.create(:valid_medium, :with_video,
                                 transcription_status: :completed)
      allow(search_client).to receive(:list_media_versions)
        .and_return(medium.id => "old-version")
      expect(search_client).to receive(:invalidate_media)
        .with(medium.id, expected_video_version: "old-version")
        .and_return(false)
      expect(MampfsearchIngestJob).not_to receive(:perform_later)

      described_class.perform_now
    end

    it "invalidates orphaned IDs and ingests missing media" do
      existing_medium = FactoryBot.create(:valid_medium, :with_video,
                                          transcription_status: :completed)
      missing_medium = FactoryBot.create(:valid_medium, :with_video,
                                         transcription_status: :completed)
      videoless_medium = FactoryBot.create(:valid_medium, video: nil)
      non_existent_id = 99_999

      allow(search_client).to receive(:list_media_versions).and_return(
        existing_medium.id => existing_medium.video_fingerprint,
        videoless_medium.id => "old-version",
        non_existent_id => "old-version"
      )
      allow(search_client).to receive(:invalidate_media).and_return(true)

      expect(search_client).to receive(:invalidate_media)
        .with(videoless_medium.id, expected_video_version: "old-version")
        .and_return(true)
      expect(search_client).to receive(:invalidate_media)
        .with(non_existent_id, expected_video_version: "old-version")
        .and_return(true)
      expect(MampfsearchIngestJob).to receive(:perform_later).with(missing_medium.id)

      described_class.perform_now

      expect(missing_medium.reload.transcription_status).to eq("completed")
    end

    it "logs a warning and recovers gracefully when search client raises MampfSearchError" do
      allow(search_client).to receive(:list_media_versions).and_raise(
        SearchClient::MampfSearchError, "Connection failed"
      )
      expect(Rails.logger).to receive(:warn)
        .with(/Search index reconciliation skipped.*Connection failed/)

      expect { described_class.perform_now }.not_to raise_error
    end

    it "caps enqueuing of missing media when in-flight jobs approach threshold" do
      FactoryBot.create_list(:valid_medium, 12, :with_video,
                             transcription_status: :queued,
                             transcription_requested_at: 5.minutes.ago)
      missing_media = FactoryBot.create_list(:valid_medium, 5, :with_video,
                                             transcription_status: :completed)
      allow(search_client).to receive(:list_media_versions).and_return({})

      RSpec::Mocks.space.proxy_for(MampfsearchIngestJob).reset
      # 15 max in-flight - 12 existing queued = 3 batch size
      expect(MampfsearchIngestJob).to receive(:perform_later).exactly(3).times

      described_class.perform_now

      expect(Medium.where(transcription_status: :queued).count).to eq(12)
      expect(missing_media.count { |m| m.reload.completed? }).to eq(5)
    end

    it "does not enqueue missing media when in-flight queued jobs are at threshold" do
      FactoryBot.create_list(:valid_medium, SearchClient::MAX_IN_FLIGHT_TRANSCRIPTIONS,
                             :with_video,
                             transcription_status: :queued,
                             transcription_requested_at: 5.minutes.ago)
      missing_medium = FactoryBot.create(:valid_medium, :with_video,
                                         transcription_status: :completed)
      allow(search_client).to receive(:list_media_versions).and_return({})

      RSpec::Mocks.space.proxy_for(MampfsearchIngestJob).reset
      expect(MampfsearchIngestJob).not_to receive(:perform_later)

      described_class.perform_now

      expect(missing_medium.reload.transcription_status).to eq("completed")
    end
  end
end
