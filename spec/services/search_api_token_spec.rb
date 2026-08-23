require "rails_helper"

RSpec.describe(SearchApiToken, :mampfsearch) do
  let(:secret) { "test-secret-key-at-least-32-characters-long" }

  around do |example|
    original = ENV.fetch("MAMPFSEARCH_API_SECRET", nil)
    ENV["MAMPFSEARCH_API_SECRET"] = secret
    example.run
  ensure
    ENV["MAMPFSEARCH_API_SECRET"] = original
  end

  describe ".generate and .verify!" do
    it "generates a valid token and verifies it for the expected scope" do
      token = described_class.generate(scope: "/lesson/search")
      payload = described_class.verify!(token, scope: "/lesson/search")

      expect(payload).to include(
        "purpose" => "mampfsearch_api",
        "scope" => "/lesson/search"
      )
      expect(payload["expires_at"]).to be > Time.current.to_i
      expect(payload["nonce"]).to be_present
    end

    it "rejects a token with a different scope" do
      token = described_class.generate(scope: "/lesson/search")

      expect do
        described_class.verify!(token, scope: "/lesson/ingest")
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects an expired token" do
      token = described_class.generate(scope: "/lesson/search", ttl: -1.second)

      expect do
        described_class.verify!(token, scope: "/lesson/search")
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects a tampered token" do
      token = described_class.generate(scope: "/lesson/search")
      payload, signature = token.split(".", 2)
      tampered_token = "#{payload}.#{signature.reverse}"

      expect do
        described_class.verify!(tampered_token, scope: "/lesson/search")
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects a malformed token" do
      expect do
        described_class.verify!("not.a.valid.token.shape", scope: "/lesson/search")
      end.to raise_error(described_class::InvalidTokenError)

      expect do
        described_class.verify!("", scope: "/lesson/search")
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "raises ServiceUnavailableError when MAMPFSEARCH_API_SECRET is unset" do
      ENV["MAMPFSEARCH_API_SECRET"] = nil

      expect do
        described_class.generate(scope: "/lesson/search")
      end.to raise_error(SearchClient::ServiceUnavailableError,
                         /MAMPFSEARCH_API_SECRET is not configured/)

      expect do
        described_class.verify!("any.token", scope: "/lesson/search")
      end.to raise_error(SearchClient::ServiceUnavailableError,
                         /MAMPFSEARCH_API_SECRET is not configured/)
    end
  end
end
