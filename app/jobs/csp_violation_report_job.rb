class CspViolationReportJob < ApplicationJob
  queue_as :default

  def perform(report:, remote_ip:, user_agent:)
    CspViolationReport.create!(
      CspViolationReport.attributes_from_report(
        report,
        remote_ip: remote_ip,
        user_agent: user_agent
      )
    )
  end
end
