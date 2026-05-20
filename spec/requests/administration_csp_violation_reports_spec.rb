require "rails_helper"

RSpec.describe("Administration CSP violation reports", type: :request) do
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:user) { create(:confirmed_user) }

  before do
    CspViolationReport.create!(
      document_uri: "https://mampf.example/lectures/1",
      effective_directive: "script-src-elem",
      blocked_uri: "https://example.invalid/script.js",
      raw_report: { "csp-report" => { "effective-directive" => "script-src-elem" } }
    )
  end

  it "shows reports to admins" do
    sign_in admin

    get csp_violation_reports_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("script-src-elem")
    expect(response.body).to include("https://example.invalid/script.js")
  end

  it "does not show reports to non-admin users" do
    sign_in user

    get csp_violation_reports_path

    expect(response).to redirect_to(root_url)
  end
end
