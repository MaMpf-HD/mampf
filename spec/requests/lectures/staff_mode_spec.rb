require "rails_helper"

RSpec.describe("Lecture view and edit mode", type: :request) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:toggle) { 'data-testid="lecture-mode-toggle"' }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
    create(:lecture_bookmark, user: student, lecture: lecture)
  end

  context "as an editor who is no admin" do
    before { sign_in(editor) }

    it "has no administration area" do
      get administration_path

      expect(response).to redirect_to(root_url)
    end

    it "offers the toggle while viewing the lecture" do
      get lecture_outline_path(lecture)

      expect(response.body).to include(toggle)
      expect(response.body).not_to include("admin-background")
    end

    it "edits the lecture in the regular layout on a dotted background" do
      get edit_lecture_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(toggle, "admin-background")
      expect(response.body).not_to include("admin-navbars-container", 'id="sidebar"')
    end

    it "answers the switch back to viewing with the sidebar in the frame" do
      get lecture_outline_path(lecture), headers: { "Turbo-Frame" => "lecture-mode" }

      expect(response.body).to include('id="lecture-mode"', toggle,
                                       'id="sidebar"')
      expect(response.body).not_to include("<html")
    end
  end

  context "as an admin" do
    let(:admin) { create(:confirmed_user, admin: true) }

    before { sign_in(admin) }

    it "edits the lecture in the regular layout with the administration navbar" do
      get edit_lecture_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("admin-navbars-container", 'id="lecture-mode"',
                                       toggle, "admin-background")
      expect(response.body).not_to include('class="navbars-container"', 'id="sidebar"')
    end

    it "keeps the administration navbar while viewing the lecture" do
      get lecture_outline_path(lecture)

      expect(response.body).to include("admin-navbars-container", 'id="sidebar"')
      expect(response.body).not_to include('class="navbars-container"')
    end

    it "switches between view and edit mode in place" do
      get lecture_outline_path(lecture)

      expect(response.body).to include(toggle, 'data-turbo-frame="lecture-mode"')
    end
  end

  context "as a student" do
    before { sign_in(student) }

    it "shows the lecture's title bar, but no toggle" do
      get lecture_outline_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-testid="lecture-title-bar"')
      expect(response.body).not_to include(toggle)
    end

    it "cannot open the edit page" do
      get edit_lecture_path(lecture)

      expect(response).to redirect_to(root_url)
    end
  end
end
