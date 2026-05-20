class CspViolationReport < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }

  validates :raw_report, presence: true

  def self.attributes_from_report(report, remote_ip:, user_agent:)
    report = report.deep_stringify_keys
    details = report.fetch("csp-report", report)
    details = {} unless details.is_a?(Hash)

    {
      document_uri: details["document-uri"],
      referrer: details["referrer"],
      violated_directive: details["violated-directive"],
      effective_directive: details["effective-directive"],
      original_policy: details["original-policy"],
      disposition: details["disposition"],
      blocked_uri: details["blocked-uri"],
      status_code: integer_value(details["status-code"]),
      source_file: details["source-file"],
      line_number: integer_value(details["line-number"]),
      column_number: integer_value(details["column-number"]),
      script_sample: details["script-sample"],
      ip_address: remote_ip,
      user_agent: user_agent,
      raw_report: report
    }
  end

  def self.integer_value(value)
    Integer(value) if value.present?
  rescue ArgumentError, TypeError
    nil
  end
  private_class_method :integer_value
end