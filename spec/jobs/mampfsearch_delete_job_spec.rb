require "rails_helper"

RSpec.describe(MampfsearchDeleteJob, :mampfsearch, type: :job) do
  describe "#perform" do
    before do
      allow(SearchClient.instance).to receive(:configured?).and_return(true)
    end

    it "calls SearchClient.instance.delete_media with media_id" do
      expect(SearchClient.instance).to receive(:delete_media).with(123)

      described_class.new.perform(123)
    end

    it "rescues MampfSearchError gracefully" do
      allow(SearchClient.instance).to receive(:delete_media).with(123)
                                                            .and_raise(
                                                              SearchClient::ServiceUnavailableError,
                                                              "offline"
                                                            )

      expect { described_class.new.perform(123) }.not_to raise_error
    end

    it "does not contact MampfSearch when it is not configured" do
      allow(SearchClient.instance).to receive(:configured?).and_return(false)
      expect(SearchClient.instance).not_to receive(:delete_media)

      described_class.new.perform(123)
    end
  end
end
