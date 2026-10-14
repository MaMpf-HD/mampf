require "rails_helper"

RSpec.describe(MampfsearchMetadataSyncJob, :mampfsearch, type: :job) do
  it "updates hierarchy without changing transcription state" do
    medium = FactoryBot.create(:lesson_medium, :with_video,
                               transcription_status: :completed)
    hierarchy = Mampfsearch::Hierarchy.for(medium)
    search_client = instance_double(SearchClient)
    allow(SearchClient).to receive(:instance).and_return(search_client)
    expect(search_client).to receive(:sync_media_hierarchy).with(
      medium.id, video_version: medium.video_fingerprint, hierarchy: hierarchy
    )

    described_class.perform_now(medium.id)

    expect(medium.reload).to be_completed
  end
end
