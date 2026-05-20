require "rails_helper"

RSpec.describe("CSP violation reports", type: :request) do
  let(:payload) do
    {
      "csp-report" => {
        "document-uri" => "https://mampf.example/lectures/1",
        "referrer" => "",
        "violated-directive" => "script-src-elem",
        "effective-directive" => "script-src-elem",
        "original-policy" => "default-src 'self'; " \
                             "report-uri /csp-violation-report-endpoint",
        "disposition" => "report",
        "blocked-uri" => "https://example.invalid/script.js",
        "status-code" => 200,
        "source-file" => "https://mampf.example/lectures/1",
        "line-number" => 12,
        "column-number" => 3,
        "script-sample" => ""
      }
    }
  end

  describe "POST /csp-violation-report-endpoint" do
    it "accepts unauthenticated reports and stores normalized data" do
      expect do
        perform_enqueued_jobs do
          post(csp_violation_report_endpoint_path,
               params: payload.to_json,
               headers: { "CONTENT_TYPE" => "application/csp-report",
                          "User-Agent" => "RSpec" })
        end
      end.to change(CspViolationReport, :count).by(1)

      report = CspViolationReport.last
      expect(response).to have_http_status(:no_content)
      expect(report.effective_directive).to eq("script-src-elem")
      expect(report.blocked_uri).to eq("https://example.invalid/script.js")
      expect(report.status_code).to eq(200)
      expect(report.user_agent).to eq("RSpec")
      expect(report.raw_report).to eq(payload)
    end

    it "rejects malformed JSON" do
      expect do
        post(csp_violation_report_endpoint_path,
             params: "not JSON",
             headers: { "CONTENT_TYPE" => "application/csp-report" })
      end.not_to have_enqueued_job(CspViolationReportJob)

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects oversized reports" do
      expect do
        post(csp_violation_report_endpoint_path,
             params: { report: "a" * 70.kilobytes }.to_json,
             headers: { "CONTENT_TYPE" => "application/csp-report" })
      end.not_to have_enqueued_job(CspViolationReportJob)

      expect(response).to have_http_status(:payload_too_large)
    end
  end

  describe "Content-Security-Policy-Report-Only header" do
    it "points browsers to the report endpoint" do
      get "/altcha"

      expect(response.headers["Content-Security-Policy-Report-Only"])
        .to include("report-uri /csp-violation-report-endpoint")
    end
  end
end
