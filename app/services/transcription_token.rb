class TranscriptionToken
  ALGORITHM = "SHA256".freeze
  VIDEO_TTL = 5.minutes
  TRANSCRIPT_TTL = 1.hour
  PURPOSES = ["video", "transcript"].freeze

  class InvalidTokenError < StandardError; end

  class << self
    def generate(medium_id:, purpose:, ttl:)
      purpose = purpose.to_s
      validate_purpose!(purpose)

      payload = {
        "medium_id" => Integer(medium_id),
        "purpose" => purpose,
        "expires_at" => ttl.from_now.to_i,
        "nonce" => SecureRandom.hex(16)
      }
      encoded_payload = Base64.urlsafe_encode64(payload.to_json, padding: false)

      "#{encoded_payload}.#{signature_for(encoded_payload)}"
    end

    def verify!(token, purpose:)
      encoded_payload, supplied_signature = token.to_s.split(".", 2)
      raise(InvalidTokenError) if encoded_payload.blank? || supplied_signature.blank?

      expected_signature = signature_for(encoded_payload)
      unless supplied_signature.bytesize == expected_signature.bytesize &&
             ActiveSupport::SecurityUtils.secure_compare(
               supplied_signature, expected_signature
             )
        raise(InvalidTokenError)
      end

      payload = JSON.parse(Base64.urlsafe_decode64(encoded_payload))
      validate_payload!(payload, purpose.to_s)
      payload
    rescue ArgumentError, JSON::ParserError, KeyError, TypeError
      raise(InvalidTokenError)
    end

    private

      def signature_for(encoded_payload)
        OpenSSL::HMAC.hexdigest(
          ALGORITHM,
          Rails.application.secret_key_base,
          encoded_payload
        )
      end

      def validate_purpose!(purpose)
        raise(InvalidTokenError) unless PURPOSES.include?(purpose)
      end

      def validate_payload!(payload, purpose)
        validate_purpose!(purpose)
        raise(InvalidTokenError) unless payload.is_a?(Hash)
        raise(InvalidTokenError) unless payload.fetch("purpose") == purpose
        raise(InvalidTokenError) unless Integer(payload.fetch("medium_id")).positive?
        raise(InvalidTokenError) unless Integer(payload.fetch("expires_at")) > Time.current.to_i
        raise(InvalidTokenError) if payload.fetch("nonce").to_s.empty?
      end
  end
end
