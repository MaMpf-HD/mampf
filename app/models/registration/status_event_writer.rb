module Registration
  class StatusEventWriter
    def self.call(...)
      new(...).call
    end

    # rubocop:disable Metrics/ParameterLists
    def initialize(registrations:, action:, reason_type: nil, reason_code: nil,
                   actor: nil, correlation_id: nil, schema_version: 1,
                   snapshot: {})
      @registrations = Array(registrations)
      @action = action
      @reason_type = reason_type
      @reason_code = reason_code
      @actor = actor
      @correlation_id = correlation_id
      @schema_version = schema_version
      @snapshot = snapshot
    end
    # rubocop:enable Metrics/ParameterLists

    def call
      return [] if registrations.empty?

      Registration::StatusEvent.transaction do
        registrations.map do |registration|
          Registration::StatusEvent.create!(
            registration: registration,
            registration_campaign: registration.registration_campaign,
            action: action,
            reason_type: reason_type_for(registration),
            reason_code: reason_code_for(registration),
            actor: actor,
            correlation_id: correlation_id,
            schema_version: schema_version,
            snapshot: snapshot_for(registration)
          )
        end
      end
    end

    private

      attr_reader :registrations, :action, :reason_type, :reason_code,
                  :actor, :correlation_id, :schema_version, :snapshot

      def snapshot_for(registration)
        value = snapshot.respond_to?(:call) ? snapshot.call(registration) : snapshot
        value || {}
      end

      def reason_type_for(registration)
        reason_type.respond_to?(:call) ? reason_type.call(registration) : reason_type
      end

      def reason_code_for(registration)
        reason_code.respond_to?(:call) ? reason_code.call(registration) : reason_code
      end
  end
end
