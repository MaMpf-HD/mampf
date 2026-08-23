require "rails_helper"

RSpec.describe MampfsearchDeleteJob, :mampfsearch, type: :job do
  describe "#perform" do
    it "calls SearchClient.instance.delete_media with media_id" do
      expect(SearchClient.instance).to receive(:delete_media).with(123)

      described_class.new.perform(123)
    end

    it "rescues MampfSearchError gracefully" do
      allow(SearchClient.instance).to receive(:delete_media).with(123)
        .and_raise(SearchClient::ServiceUnavailableError, "offline")

      expect { described_class.new.perform(123) }.not_to raise_error
    end
  end
end
