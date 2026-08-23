require "rails_helper"

RSpec.describe(TranscriptionToken) do
  describe ".verify!" do
    it "verifies a token for its intended medium and purpose" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes
      )

      expect(described_class.verify!(token, purpose: :video)).to include(
        "medium_id" => 42,
        "purpose" => "video"
      )
    end

    it "rejects a token with a different purpose" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes
      )

      expect do
        described_class.verify!(token, purpose: :transcript)
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects an expired token" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: -1.second
      )

      expect do
        described_class.verify!(token, purpose: :video)
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects a tampered token" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes
      )
      payload, signature = token.split(".", 2)
      tampered_token = "#{payload}.#{signature.reverse}"

      expect do
        described_class.verify!(tampered_token, purpose: :video)
      end.to raise_error(described_class::InvalidTokenError)
    end
  end
end
