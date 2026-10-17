require "rails_helper"

RSpec.describe("Responses to a rescued error", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:stream_only) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:turbo_form) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }
  let(:browser) do
    { "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" }
  end

  before { sign_in user }

  describe "a stale CSRF token" do
    around do |example|
      protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = protection
    end

    let(:stale_token) { { "X-CSRF-Token" => "stale" } }

    it "answers a fetch call asking for a Turbo Stream only with 422" do
      post dashboard_lecture_bookmark_path(lecture),
           headers: stream_only.merge(stale_token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq(I18n.t("controllers.session_expired"))
      expect(lecture.in?(user.reload.lectures)).to be(false)
    end

    it "answers a fetch call asking for JSON only with 422" do
      user.bookmark_lecture!(lecture)

      patch dashboard_lecture_washi_tape_path(lecture),
            params: { washi_tape: { tape_color: "mint" } }.to_json,
            headers: stale_token.merge("Accept" => "application/json",
                                       "Content-Type" => "application/json")

      expect(response).to have_http_status(:unprocessable_content)
      expect(Dashboard::CardStyle.where(user: user, lecture: lecture)).to be_empty
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

    it "redirects a CSV export opened in the browser to the dashboard" do
      tutorial = create(:tutorial, lecture: lecture)
      assignment = create(:assignment, lecture: lecture)

      get export_teams_to_csv_path(tutorial, ass_id: assignment.id, format: :csv),
          headers: browser

      expect(response).to redirect_to(root_url)
    end
  end
end
