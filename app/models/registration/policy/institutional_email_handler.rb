module Registration
  class Policy
    # Handles the "Institutional Email" policy.
    # Checks if the user's email address ends with one of the allowed domains.
    class InstitutionalEmailHandler < Handler
      def evaluate(user)
        return fail_result(:configuration_error, "No allowed domains configured") if domains.empty?

        email = user.email.to_s.downcase
        allowed = domains.any? { |domain| email.end_with?("@#{domain}") }

        if allowed
          pass_result(:domain_ok)
        else
          fail_result(:institutional_email_mismatch, "Email domain not allowed",
                      allowed_domains: domains)
        end
      end

      def validate
        return unless domains.empty?

        policy.errors.add(:allowed_domains, I18n.t("registration.policy.errors.missing_domains"))
      end

      def summary
        domains.join(", ")
      end

      private

        def domains
          @domains ||= parse_domains(config["allowed_domains"])
        end

        def parse_domains(raw)
          raw_domains = raw
          list = if raw_domains.is_a?(String)
            raw_domains.split(",")
          else
            Array(raw_domains)
          end
          list.map { |d| (d || "").strip.downcase }.reject(&:empty?)
        end
    end
  end
end
