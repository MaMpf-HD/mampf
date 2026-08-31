class SearchApiToken
  PURPOSE = "mampfsearch_api".freeze
  ALGORITHM = "SHA256".freeze
  TOKEN_TTL = 60.seconds

  class InvalidTokenError < StandardError; end

  class << self
    def generate(scope:, ttl: TOKEN_TTL)
      secret = ENV.fetch("MAMPFSEARCH_API_SECRET", nil)
      if secret.blank?
        raise(SearchClient::ServiceUnavailableError,
              "MAMPFSEARCH_API_SECRET is not configured.")
      end

      payload = {
        "purpose" => PURPOSE,
        "scope" => scope.to_s,
        "expires_at" => (Time.current + ttl).to_i,
        "nonce" => SecureRandom.hex(8)
      }
      encoded_payload = Base64.urlsafe_encode64(payload.to_json, padding: false)

      "#{encoded_payload}.#{signature_for(encoded_payload, secret)}"
    end

    def verify!(token, scope:, purpose: PURPOSE)
      secret = ENV.fetch("MAMPFSEARCH_API_SECRET", nil)
      if secret.blank?
        raise(SearchClient::ServiceUnavailableError,
              "MAMPFSEARCH_API_SECRET is not configured.")
      end

      encoded_payload, supplied_signature = token.to_s.split(".", 2)
      raise(InvalidTokenError) if encoded_payload.blank? || supplied_signature.blank?

      expected_signature = signature_for(encoded_payload, secret)
      unless supplied_signature.bytesize == expected_signature.bytesize &&
             ActiveSupport::SecurityUtils.secure_compare(
               supplied_signature, expected_signature
             )
        raise(InvalidTokenError)
      end

      payload = JSON.parse(Base64.urlsafe_decode64(encoded_payload))
      validate_payload!(payload, scope: scope.to_s, purpose: purpose.to_s)
      payload
    rescue ArgumentError, JSON::ParserError, KeyError, TypeError
      raise(InvalidTokenError)
    end

    private

      def signature_for(encoded_payload, secret)
        OpenSSL::HMAC.hexdigest(ALGORITHM, secret, encoded_payload)
      end

      def validate_payload!(payload, scope:, purpose:)
        raise(InvalidTokenError) unless payload.is_a?(Hash)
        raise(InvalidTokenError) unless payload.fetch("purpose") == purpose
        raise(InvalidTokenError) unless payload.fetch("scope") == scope
        raise(InvalidTokenError) unless Integer(payload.fetch("expires_at")) > Time.current.to_i
        raise(InvalidTokenError) if payload.fetch("nonce").to_s.empty?
      end
  end
end
