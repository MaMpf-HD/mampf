require "rails_helper"

RSpec.describe("Redirects after a rescued error", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:stream_only) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:turbo_form) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  before { sign_in user }

  describe "a stale CSRF token" do
    around do |example|
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    let(:stale_token) { { "X-CSRF-Token" => "stale" } }

    it "answers a fetch call asking for a Turbo Stream only with 422" do
      post dashboard_lecture_bookmark_path(lecture),
           headers: stream_only.merge(stale_token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq(I18n.t("controllers.session_expired"))
      expect(lecture.in?(user.reload.lectures)).to be(false)
    end

    it "redirects a Turbo form submission to the dashboard" do
      post dashboard_lecture_bookmark_path(lecture),
           headers: turbo_form.merge(stale_token)

      expect(response).to redirect_to(root_url)
      expect(flash[:alert]).to eq(I18n.t("controllers.session_expired"))
    end
  end

  describe "a denied authorization" do
    it "answers a fetch call asking for a Turbo Stream only with 403" do
      get edit_lecture_path(lecture), headers: stream_only

      expect(response).to have_http_status(:forbidden)
    end

    it "redirects a page request to the dashboard" do
      get edit_lecture_path(lecture)

      expect(response).to redirect_to(root_url)
    end
  end
end
