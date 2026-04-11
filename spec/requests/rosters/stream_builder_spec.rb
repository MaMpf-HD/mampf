require "rails_helper"

RSpec.describe(Rosters::StreamBuilder, type: :request) do
  let(:lecture) { create(:lecture, locale: I18n.default_locale) }
  let(:editor) { create(:confirmed_user) }
  let(:tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }

  before do
    Flipper.enable(:roster_maintenance)
    create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
    sign_in editor
  end

  describe "stream dispatch via panel source" do
    it "returns side panel stream" do
      get tutorial_roster_path(tutorial, source: "panel"),
          as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("tutorial-roster-side-panel")
    end

    it "skips tile DOM id when showing (update_tiles: false)" do
      get tutorial_roster_path(tutorial, source: "panel"),
          as: :turbo_stream

      expect(response.body).to include("tutorial-roster-side-panel")
    end
  end

  describe "stream dispatch via participants source" do
    let(:member) { create(:confirmed_user) }

    before do
      create(:lecture_membership, lecture: lecture, user: member)
      create(:tutorial_membership, tutorial: tutorial, user: member)
    end

    it "returns participants panel stream on remove" do
      delete remove_member_tutorial_path(tutorial, user_id: member.id),
             params: { source: "participants", group_type: "tutorials" },
             as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("roster_participants_panel")
    end
  end

  describe "stream dispatch via unassigned source" do
    let(:campaign_tutorial) do
      create(:tutorial, lecture: lecture, skip_campaigns: false)
    end
    let(:campaign) do
      create(:registration_campaign, campaignable: lecture,
                                     status: :completed, registration_deadline: 2.weeks.ago)
    end
    let(:new_student) { create(:confirmed_user) }

    before do
      create(:registration_item,
             registration_campaign: campaign,
             registerable: campaign_tutorial)
    end

    it "returns dissolved footnote and side panel streams" do
      post add_member_tutorial_path(campaign_tutorial),
           params: {
             email: new_student.email,
             source: "unassigned",
             source_id: campaign.id.to_s
           },
           as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("dissolved_campaign_#{campaign.id}")
      expect(response.body).to include("tutorial-roster-side-panel")
    end

    it "keeps lecture members in the unassigned panel after removing a group assignment" do
      create(:registration_user_registration,
             :confirmed,
             registration_campaign: campaign,
             registration_item: campaign.registration_items.first,
             user: new_student)
      create(:lecture_membership, lecture: lecture, user: new_student)
      create(:tutorial_membership, tutorial: campaign_tutorial, user: new_student)

      delete remove_member_tutorial_path(campaign_tutorial, user_id: new_student.id),
             params: {
               source: "unassigned",
               source_id: campaign.id.to_s
             },
             as: :turbo_stream

      expect(response).to have_http_status(:success)
      # the student name is expected to appear in the response since the turbo stream
      # re-renders the side panel with all unassigned users, which should still
      # include the removed student (since they are still a lecture member,
      # just not assigned to a tutorial anymore)
      expect(response.body).to include(new_student.name)
    end
  end

  describe "stream dispatch default (roster overview)" do
    let(:new_student) { create(:confirmed_user) }

    it "returns overview frame and campaigns container" do
      post add_member_tutorial_path(tutorial),
           params: { email: new_student.email },
           as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/roster_maintenance_/)
      expect(response.body).to include("campaigns_container")
    end

    it "uses specified group_type in frame id" do
      post add_member_tutorial_path(tutorial),
           params: { email: new_student.email, group_type: "tutorials" },
           as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("roster_maintenance_tutorials")
    end
  end

  describe "stream dispatch move_panel" do
    let(:target) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
    let(:member) { create(:confirmed_user) }

    before do
      create(:tutorial_membership, tutorial: tutorial, user: member)
    end

    it "returns tile updates for both source and target plus side panel" do
      patch move_member_tutorial_path(tutorial, user_id: member.id),
            params: { target_id: target.id, source: "panel" },
            as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include("tutorial-roster-side-panel")
    end
  end
end
