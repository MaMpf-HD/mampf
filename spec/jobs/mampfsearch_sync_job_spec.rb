require "rails_helper"

RSpec.describe(MampfsearchSyncJob, :mampfsearch, type: :job) do
  let(:search_client) { instance_double(SearchClient) }

  before do
    allow(SearchClient).to receive(:instance).and_return(search_client)
    allow(search_client).to receive(:list_media_rails_ids).and_return([])
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

    it "skips enqueuing when MampfsearchHealth.ingest_available? is false" do
      FactoryBot.create_list(:valid_medium, 3, :with_video,
                             transcription_status: :not_transcribed)

      RSpec::Mocks.space.proxy_for(MampfsearchIngestJob).reset
      allow(MampfsearchHealth).to receive(:ingest_available?).and_return(false)

      expect(MampfsearchIngestJob).not_to receive(:perform_later)

      described_class.perform_now
    end
  end

  describe "#reconcile_search_index" do
    it "enqueues delete jobs for orphaned IDs and ingest jobs for missing media" do
      existing_medium = FactoryBot.create(:valid_medium, :with_video,
                                          transcription_status: :completed)
      missing_medium = FactoryBot.create(:valid_medium, :with_video,
                                         transcription_status: :completed)
      videoless_medium = FactoryBot.create(:valid_medium, video: nil)
      non_existent_id = 99_999

      allow(search_client).to receive(:list_media_rails_ids)
        .and_return([existing_medium.id, videoless_medium.id, non_existent_id])

      expect(MampfsearchDeleteJob).to receive(:perform_later).with(videoless_medium.id)
      expect(MampfsearchDeleteJob).to receive(:perform_later).with(non_existent_id)
      expect(MampfsearchDeleteJob).not_to receive(:perform_later).with(existing_medium.id)
      expect(MampfsearchIngestJob).to receive(:perform_later).with(missing_medium.id)

      described_class.perform_now
    end

    it "logs a warning and recovers gracefully when search client raises MampfSearchError" do
      allow(search_client).to receive(:list_media_rails_ids).and_raise(
        SearchClient::MampfSearchError, "Connection failed"
      )
      expect(Rails.logger).to receive(:warn)
        .with(/Search index reconciliation skipped.*Connection failed/)

      expect { described_class.perform_now }.not_to raise_error
    end
  end
end
