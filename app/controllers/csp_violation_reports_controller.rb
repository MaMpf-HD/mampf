class CspViolationReportsController < ApplicationController
  MAX_REPORT_BYTES = 64.kilobytes

  skip_before_action :authenticate_user!
  skip_before_action :set_current_user
  skip_before_action :verify_authenticity_token

  def create
    raw_report = request.raw_post
    return head :payload_too_large if raw_report.bytesize > MAX_REPORT_BYTES

    report = parse_report(raw_report)
    return head :bad_request unless report.is_a?(Hash) && report.present?

    CspViolationReportJob.perform_later(
      report: report,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent.to_s
    )

    head :no_content
  end

  private

    def parse_report(raw_report)
      JSON.parse(raw_report)
    rescue JSON::ParserError
      nil
    end
end