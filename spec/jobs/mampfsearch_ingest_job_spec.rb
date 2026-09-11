require "rails_helper"

RSpec.describe(MampfsearchIngestJob, :mampfsearch, type: :job) do
  let(:medium) { FactoryBot.create(:valid_medium, :with_video) }

  before do
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
      SearchClient::ServiceUnavailableError, "service unavailable"
    )
    expect(Rails.logger).to receive(:error).with(/permanently failed/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_status).to eq("failed_permanently")
    expect(medium.transcription_error).to include("service unavailable")
  end

  it "increments attempts and marks failed_temporarily on an ingestion error" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      SearchClient::ServiceUnavailableError, "503 unavailable"
    )

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to include("503 unavailable")
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
end
