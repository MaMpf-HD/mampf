require "rails_helper"

RSpec.describe("Dev") do
  describe "GET /users/sign_in" do
    it "offers a test login for the last created Playwright user" do
      get new_user_session_path(locale: :en)

      expect(response.body).to include("Login as last created Playwright user")
    end
  end

  describe "POST /dev/teacher_login" do
    it "is not routable outside of development" do
      teacher_routes = Rails.application.routes.routes.select do |r|
        r.path.spec.to_s.include?("dev/teacher_login")
      end
      expect(teacher_routes).to be_empty
    end
  end

  describe "POST /dev/impersonate/:id" do
    it "is not routable outside of development" do
      impersonate_routes = Rails.application.routes.routes.select do |r|
        r.path.spec.to_s.include?("dev/impersonate")
      end
      expect(impersonate_routes).to be_empty
    end
  end

  describe "POST /cypress/playwright_user_login" do
    it "signs in the last created Playwright user" do
      create(:confirmed_user_en, email: "student-1-old@play")
      last_playwright_user = create(:confirmed_user_en,
                                    email: "teacher-1-new@play")
      create(:confirmed_user_en, email: "student-1-new@example.com")

      post cypress_playwright_user_login_path

      expect(response).to redirect_to(root_path)
      expect(request.env["warden"].user(:user)).to eq(last_playwright_user)
    end

    it "redirects back to the login page when there is no Playwright user" do
      post cypress_playwright_user_login_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
