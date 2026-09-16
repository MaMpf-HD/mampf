require "rails_helper"

RSpec.describe(TranscriptionToken, :mampfsearch) do
  describe ".verify!" do
    it "supports a transcription failure callback token" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :transcription_failed,
        ttl: described_class::FAILED_TTL,
        video_version: "video-version"
      )

      expect(described_class.verify!(token, purpose: :transcription_failed)).to include(
        "medium_id" => 42,
        "purpose" => "transcription_failed"
      )
    end

    it "verifies a token for its intended medium and purpose" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes,
        video_version: "video-version"
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
        ttl: 5.minutes,
        video_version: "video-version"
      )

      expect do
        described_class.verify!(token, purpose: :transcript)
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects an expired token" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: -1.second,
        video_version: "video-version"
      )

      expect do
        described_class.verify!(token, purpose: :video)
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects a tampered token" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes,
        video_version: "video-version"
      )
      payload, signature = token.split(".", 2)
      tampered_token = "#{payload}.#{signature.reverse}"

      expect do
        described_class.verify!(tampered_token, purpose: :video)
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "encodes and verifies video_version when provided" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes,
        video_version: "abc123version"
      )

      expect(described_class.verify!(token, purpose: :video)).to include(
        "medium_id" => 42,
        "purpose" => "video",
        "video_version" => "abc123version"
      )
    end

    it "rejects a signed token without video_version" do
      token = described_class.generate(
        medium_id: 42,
        purpose: :video,
        ttl: 5.minutes,
        video_version: "video-version"
      )
      payload = JSON.parse(Base64.urlsafe_decode64(token.split(".", 2).first))
      payload.delete("video_version")
      encoded_payload = Base64.urlsafe_encode64(payload.to_json, padding: false)
      signature = described_class.send(:signature_for, encoded_payload)

      expect do
        described_class.verify!("#{encoded_payload}.#{signature}", purpose: :video)
      end.to raise_error(described_class::InvalidTokenError)
    end

    it "rejects a blank video_version when generating a token" do
      expect do
        described_class.generate(
          medium_id: 42,
          purpose: :video,
          ttl: 5.minutes,
          video_version: nil
        )
      end.to raise_error(described_class::InvalidTokenError)
    end
  end
end
