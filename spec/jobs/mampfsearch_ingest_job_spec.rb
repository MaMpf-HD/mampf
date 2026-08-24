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

  it "skips medium that is not transcribable and logs info" do
    medium_without_video = FactoryBot.create(:valid_medium, video: nil)
    expect(Mampfsearch::IngestionService).not_to receive(:transcribe)
    allow(Rails.logger).to receive(:info).and_call_original
    expect(Rails.logger).to receive(:info).with(/not transcribable/)

    described_class.perform_now(medium_without_video.id)
  end

  it "marks failed_permanently when a failed_temporarily medium has reached max attempts" do
    medium.update!(
      transcription_status: :failed_temporarily,
      transcription_attempts: SearchClient::MAX_TRANSCRIPTION_ATTEMPTS
    )
    expect(Mampfsearch::IngestionService).not_to receive(:transcribe)
    allow(Rails.logger).to receive(:warn).and_call_original
    expect(Rails.logger).to receive(:warn).with(/permanently failed/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_status).to eq("failed_permanently")
    expect(medium.transcription_error).to include("Exceeded max transcription attempts")
  end

  it "increments attempts and marks failed_temporarily on ServiceUnavailableError" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      SearchClient::ServiceUnavailableError, "503 unavailable"
    )

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to include("503 unavailable")
  end

  it "increments attempts, marks failed_permanently, and logs error on MampfSearchError" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      SearchClient::MampfSearchError, "400 Bad Request"
    )
    expect(Rails.logger).to receive(:error).with(/permanently failed/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_permanently")
    expect(medium.transcription_error).to include("400 Bad Request")
  end

  it "marks failed_temporarily and skips transcribe when ingestion service is offline" do
    allow(MampfsearchHealth).to receive(:ingest_available?).and_return(false)
    expect(Mampfsearch::IngestionService).not_to receive(:transcribe)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to include("offline")
  end

  it "rescues StandardError, marks failed_temporarily, and logs error" do
    allow(Mampfsearch::IngestionService).to receive(:transcribe).and_raise(
      StandardError, "Unexpected DB connection drop"
    )
    expect(Rails.logger).to receive(:error).with(/Unexpected error/)

    described_class.perform_now(medium.id)

    medium.reload
    expect(medium.transcription_attempts).to eq(1)
    expect(medium.transcription_status).to eq("failed_temporarily")
    expect(medium.transcription_error).to include("Unexpected DB connection drop")
  end
end
