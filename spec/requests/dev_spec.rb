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

  describe "local-only routes" do
    it "does not draw login and impersonation routes outside local environments" do
      allow(Rails.env).to receive(:local?).and_return(false)
      Rails.application.reload_routes!

      route_paths = Rails.application.routes.routes.map { |r| r.path.spec.to_s }

      expect(route_paths).not_to include(a_string_including("/dev/impersonate"))
      expect(route_paths).not_to include(a_string_including("/dev/teacher_login"))
      expect(route_paths).not_to include(a_string_including("/cypress/playwright_user_login"))
    ensure
      allow(Rails.env).to receive(:local?).and_call_original
      Rails.application.reload_routes!
    end
  end

  describe "POST /dev/impersonate/:id" do
    it "is offered in the navbar for Playwright tests" do
      current_user = create(:confirmed_user_en, email: "teacher-1@play")
      target_user = create(:confirmed_user_en, email: "student-1@play")
      sign_in(current_user)

      get start_path

      expect(response.body).to include(dev_impersonate_path(target_user.id))
    end

    it "switches to the selected user" do
      current_user = create(:confirmed_user_en, email: "teacher-1@play")
      target_user = create(:confirmed_user_en, email: "student-1@play")
      sign_in(current_user)
      host! "localhost"

      post dev_impersonate_path(target_user.id)

      expect(response).to redirect_to(start_path)
      follow_redirect!
      expect(controller.current_user).to eq(target_user)
    end
  end

  describe "POST /cypress/playwright_user_login" do
    it "signs in the last created Playwright user" do
      create(:confirmed_user_en, email: "student-1-old@play")
      last_playwright_user = create(:confirmed_user_en,
                                    email: "teacher-1-new@play")
      create(:confirmed_user_en, email: "student-1-new@example.com")
      host! "localhost"

      post cypress_playwright_user_login_path

      expect(response).to redirect_to(root_path)
      expect(request.env["warden"].user(:user)).to eq(last_playwright_user)
    end

    it "redirects back to the login page when there is no Playwright user" do
      host! "localhost"

      post cypress_playwright_user_login_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects non-local hosts" do
      host! "example.com"

      post cypress_playwright_user_login_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
