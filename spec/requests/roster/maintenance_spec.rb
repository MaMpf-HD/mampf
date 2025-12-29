require "rails_helper"

RSpec.describe("Roster::Maintenance", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  before do
    Flipper.enable(:item_dashboard)
    create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
  end

  describe "GET /lectures/:id/roster" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_roster_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "assigns group_type from params" do
        get lecture_roster_path(lecture, group_type: "tutorials")
        expect(response.body).to include('turbo-frame id="roster_maintenance_tutorials"')
      end

      it "defaults group_type to :all" do
        get lecture_roster_path(lecture)
        expect(response.body).to include('turbo-frame id="roster_maintenance_all"')
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_roster_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /tutorials/:id/roster" do
    let(:tutorial) { create(:tutorial, lecture: lecture, managed_by_campaign: true) }

    context "as an editor" do
      before { sign_in editor }

      it "updates the managed_by_campaign flag" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { managed_by_campaign: false } }
        expect(tutorial.reload.managed_by_campaign).to be(false)
      end

      it "redirects to the roster index" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { managed_by_campaign: false } }
        expect(response).to redirect_to(lecture_roster_path(lecture, group_type: :tutorials))
      end

      context "with turbo stream" do
        it "returns turbo stream response" do
          patch tutorial_roster_path(tutorial),
                params: { rosterable: { managed_by_campaign: false } },
                as: :turbo_stream
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body)
            .to include('turbo-stream action="replace" target="roster_maintenance_tutorials"')
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { managed_by_campaign: false } }
        expect(response).to redirect_to(root_path)
      end

      it "does not update the managed_by_campaign flag" do
        patch tutorial_roster_path(tutorial), params: { rosterable: { managed_by_campaign: false } }
        expect(tutorial.reload.managed_by_campaign).to be(true)
      end
    end
  end
end
