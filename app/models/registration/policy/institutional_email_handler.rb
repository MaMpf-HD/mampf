module Registration
  class Policy
    # Handles the "Institutional Email" policy.
    # Checks if the user's email address ends with one of the allowed domains.
    class InstitutionalEmailHandler < Handler
      def evaluate(user)
        if domains.empty?
          return fail_result(:configuration_error,
                             I18n.t("registration.policy.errors.no_allowed_domains_configured"))
        end

        email_domain = user.email.to_s.strip.downcase.split("@", 2).last
        allowed = email_domain.present? && domains.any? do |domain|
          email_domain == domain || email_domain.end_with?(".#{domain}")
        end

        if allowed
          pass_result(:domain_ok)
        else
          fail_result(:institutional_email_mismatch,
                      I18n.t("registration.policy.errors.email_domain_not_allowed"),
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
          list.map { |d| (d || "").strip.downcase.delete_prefix(".") }.reject(&:empty?)
        end
    end
  end
end
