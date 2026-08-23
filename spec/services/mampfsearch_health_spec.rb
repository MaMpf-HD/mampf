require "rails_helper"

RSpec.describe MampfsearchHealth, :mampfsearch do
  describe ".search_available? / .ingest_available?" do
    it "defaults to available when no health state is cached" do
      Rails.cache.delete(MampfsearchHealth::CACHE_KEY)

      expect(described_class.search_available?).to be(true)
      expect(described_class.ingest_available?).to be(true)
    end

    it "reflects the cached capabilities" do
      Rails.cache.write(MampfsearchHealth::CACHE_KEY,
                        { "search" => true, "ingest" => false },
                        expires_in: 1.minute)

      expect(described_class.search_available?).to be(true)
      expect(described_class.ingest_available?).to be(false)
    end
  end

  describe "#call" do
    let(:search_client) { instance_double(SearchClient) }

    before do
      allow(SearchClient).to receive(:instance).and_return(search_client)
    end

    it "writes the normalized capabilities to the cache" do
      allow(search_client).to receive(:health).and_return(
        "status" => "ok",
        "capabilities" => { "search" => true, "ingest" => true }
      )

      described_class.new.call

      cached = Rails.cache.read(MampfsearchHealth::CACHE_KEY)
      expect(cached["search"]).to be(true)
      expect(cached["ingest"]).to be(true)
    end

    it "writes a down state when the health check fails" do
      allow(search_client).to receive(:health)
        .and_raise(SearchClient::ServiceUnavailableError, "down")

      described_class.new.call

      cached = Rails.cache.read(MampfsearchHealth::CACHE_KEY)
      expect(cached["search"]).to be(false)
      expect(cached["ingest"]).to be(false)
    end
  end
end
