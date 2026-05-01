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
          { pass: false, code: code, message: message, details: details }
            .merge(sanitize_result_metadata(metadata))
        end

        def sanitize_result_metadata(metadata)
          metadata.except(*RESERVED_RESULT_KEYS)
        end
    end
  end
end
