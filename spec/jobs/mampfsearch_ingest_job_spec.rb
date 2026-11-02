require "rails_helper"

RSpec.describe(MampfsearchIngestJob, :mampfsearch, type: :job) do
  let(:medium) { FactoryBot.create(:valid_medium, :with_video) }
  let(:search_client) { instance_double(SearchClient, configured?: true) }

  before do
    allow(SearchClient).to receive(:instance).and_return(search_client)
    allow(MampfsearchHealth).to receive(:ingest_available?).and_return(true)
    allow(described_class).to receive(:perform_later)
    medium.update!(transcription_attempts: 0, transcription_status: :not_transcribed)
  end

  it "calls IngestionService.transcribe, updates status to queued, and preserves attempts" do
    expect(Mampfsearch::IngestionService).to receive(:transcribe).with(medium)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(0)
    expect(medium.transcription_status).to eq("queued")
    expect(medium.transcription_requested_at).to be_present
    expect(medium.transcription_error).to be_nil
  end

  it "preserves completed status when re-ingesting a missing index entry" do
    medium.update!(transcription_status: :completed, transcription_attempts: 1)
    expect(Mampfsearch::IngestionService).to receive(:transcribe).with(medium)

    described_class.perform_now(medium.id)

    expect(medium.reload.transcription_status).to eq("completed")
    expect(medium.transcription_attempts).to eq(1)
  end

  it "skips medium that is not transcribable" do
    medium_without_video = FactoryBot.create(:valid_medium, video: nil)
    expect(Mampfsearch::IngestionService).not_to receive(:transcribe)

    described_class.perform_now(medium_without_video.id)
  end

  it "marks failed_permanently when a failure reaches max attempts" do
    medium.update!(
      transcription_attempts: SearchClient::MAX_TRANSCRIPTION_ATTEMPTS - 1
    )
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      SearchClient::TimeoutError, "timed out"
    )
    expect(Rails.logger).to receive(:error).with(/permanently failed/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_status).to eq("failed_permanently")
    expect(medium.transcription_error).to include("timed out")
  end

  it "increments attempts and marks failed_temporarily on a timeout" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      SearchClient::TimeoutError, "timed out"
    )

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to include("timed out")
  end

  it "marks MampfSearchError as failed_temporarily until the attempt limit" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      SearchClient::MampfSearchError, "400 Bad Request"
    )
    expect(Rails.logger).to receive(:warn).with(/transcription failed/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to include("400 Bad Request")
  end

  it "marks a generic error as failed_temporarily" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      RuntimeError, "Unexpected DB connection drop"
    )
    expect(Rails.logger).to receive(:warn).with(/Unexpected DB connection drop/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to eq("Unexpected DB connection drop")
  end

  describe "availability gating" do
    context "when MampfSearch is not configured" do
      let(:search_client) { instance_double(SearchClient, configured?: false) }

      it "leaves an uploaded medium untouched" do
        expect(Mampfsearch::IngestionService).not_to receive(:transcribe)

        described_class.perform_now(medium.id)

        medium.reload
        expect(medium).to be_not_transcribed
        expect(medium.transcription_error).to be_nil
      end
    end

    context "when MampfSearch is configured but unreachable" do
      it "releases the medium without counting an attempt" do
        medium.update!(transcription_attempts: 1)
        allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
          SearchClient::ServiceUnavailableError, "offline"
        )

        described_class.perform_now(medium.id)

        medium.reload
        expect(medium).to be_not_transcribed
        expect(medium.transcription_attempts).to eq(1)
        expect(medium.transcription_requested_at).to be_nil
        expect(medium.transcription_error).to eq("offline")
      end

      it "keeps a completed medium completed" do
        medium.update!(transcription_status: :completed)
        allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
          SearchClient::ServiceUnavailableError, "offline"
        )

        described_class.perform_now(medium.id)

        expect(medium.reload).to be_completed
        expect(medium.transcription_attempts).to eq(0)
      end
    end

    context "when MampfSearch is reachable but cannot ingest" do
      before do
        allow(MampfsearchHealth).to receive(:ingest_available?).and_return(false)
      end

      it "releases a medium claimed by the scheduler without dispatching it" do
        medium.update!(transcription_status: :queued, transcription_requested_at: Time.current)
        expect(Mampfsearch::IngestionService).not_to receive(:transcribe)

        described_class.perform_now(medium.id)

        medium.reload
        expect(medium).to be_not_transcribed
        expect(medium.transcription_attempts).to eq(0)
      end
    end

    context "when MampfSearch is fully available" do
      it "dispatches the medium" do
        expect(Mampfsearch::IngestionService).to receive(:transcribe).with(medium)

        described_class.perform_now(medium.id)

        expect(medium.reload).to be_queued
      end
    end
  end
end
