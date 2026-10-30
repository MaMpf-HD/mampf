require "rails_helper"

RSpec.describe(MampfsearchMetadataSyncJob, :mampfsearch, type: :job) do
  let(:medium) do
    FactoryBot.create(:lesson_medium, :with_video, transcription_status: :completed)
  end
  let(:search_client) { instance_double(SearchClient, configured?: true) }

  before do
    allow(SearchClient).to receive(:instance).and_return(search_client)
  end

  it "updates hierarchy without changing transcription state" do
    hierarchy = Mampfsearch::Hierarchy.for(medium)
    expect(search_client).to receive(:sync_media_hierarchy).with(
      medium.id, video_version: medium.video_fingerprint, hierarchy: hierarchy
    )

    described_class.perform_now(medium.id)

    expect(medium.reload).to be_completed
  end

  it "logs MampfSearchError instead of raising for a retry" do
    allow(search_client).to receive(:sync_media_hierarchy)
      .and_raise(SearchClient::ServiceUnavailableError, "offline")
    expect(Rails.logger).to receive(:warn).with(/hierarchy of medium #{medium.id}.*offline/)

    expect { described_class.perform_now(medium.id) }.not_to raise_error
  end

  it "does not contact MampfSearch when it is not configured" do
    allow(search_client).to receive(:configured?).and_return(false)
    expect(search_client).not_to receive(:sync_media_hierarchy)

    described_class.perform_now(medium.id)
  end
end
