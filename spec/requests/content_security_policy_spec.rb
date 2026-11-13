require "rails_helper"

RSpec.describe("Content Security Policy", type: :request) do
  def directive(name)
    response.headers["content-security-policy"][/#{name} [^;]*/]
  end

  def script_nonce
    directive("script-src")[/'nonce-([^']+)'/, 1]
  end

  context "on a page" do
    before { get new_user_session_path }

    it "lets an inline script run only with a nonce" do
      expect(script_nonce).to be_present
      expect(directive("script-src")).not_to include("unsafe-inline")
    end

    it "gives the page the nonce of its header" do
      expect(response.body)
        .to include(%(<meta name="csp-nonce" content="#{script_nonce}"))
    end

    it "still allows inline styles, which cannot carry a nonce" do
      expect(directive("style-src")).to include("'unsafe-inline'")
      expect(directive("style-src")).not_to include("nonce-")
    end
  end

  it "keeps the nonce for the requests of a session" do
    user = FactoryBot.create(:confirmed_user)
    post user_session_path,
         params: { user: { email: user.email, password: user.password } }

    nonces = Array.new(2) do
      get(edit_profile_path)
      script_nonce
    end

    expect(nonces.first).to be_present
    expect(nonces.uniq.size).to eq(1)
  end
end
