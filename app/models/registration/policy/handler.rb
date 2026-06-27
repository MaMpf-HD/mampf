module Registration
  class Policy
    class Handler
      attr_reader :policy

      def initialize(policy)
        @policy = policy
      end

      def evaluate(_user)
        raise(NotImplementedError)
      end

      def batch_prepare(_user_ids)
      end

      def validate
      end

      def summary
        "-"
      end

      protected

        RESERVED_RESULT_KEYS = [:pass, :code, :message, :details].freeze

        def config
          policy.config || {}
        end

        def pass_result(code = :ok, details = {}, **metadata)
          { pass: true, code: code, details: details }
            .merge(sanitize_result_metadata(metadata))
        end

        def fail_result(code, message, details = {}, **metadata)
          metadata = sanitize_result_metadata(metadata)
          metadata = enrich_rejection_metadata(message, metadata)

          { pass: false, code: code, message: message, details: details }
            .merge(metadata)
        end

        def sanitize_result_metadata(metadata)
          metadata.except(*RESERVED_RESULT_KEYS)
        end

        def enrich_rejection_metadata(message, metadata)
          reason_code = metadata[:reason_code]
          return metadata if reason_code.blank?

          metadata.merge(
            reason_label: Registration::UserRegistration.resolve_rejection_reason_label(
              reason_code: reason_code,
              fallback_label: metadata[:reason_label] || message
            )
          )
        end
    end
  end
end
