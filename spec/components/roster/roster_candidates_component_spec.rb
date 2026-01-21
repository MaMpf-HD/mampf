require "rails_helper"

RSpec.describe(RosterCandidatesComponent, type: :component) do
  let(:fresh_user) { create(:user, email: "fresh@example.com", name: "Fresh User") }
  let(:prev_user) { create(:user, email: "prev@example.com", name: "Prev User") }
  let(:curr_user) { create(:user, email: "curr@example.com", name: "Curr User") }

  context "when group_type is tutorials" do
    let(:lecture) { create(:lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture, status: :completed) }
    let!(:item) do
      create(:registration_item, registration_campaign: campaign, registerable: tutorial)
    end

    before do
      # Fresh user: Registered, never assigned
      create(:registration_user_registration, registration_campaign: campaign, user: fresh_user,
                                              registration_item: item, materialized_at: nil)

      # Previously assigned user: Registered, materialized, but currently NOT in tutorial
      create(:registration_user_registration, registration_campaign: campaign,
                                              user: prev_user,
                                              registration_item: item,
                                              materialized_at: Time.current)

      # Currently assigned user: Registered, materialized, AND in tutorial
      create(:registration_user_registration, registration_campaign: campaign,
                                              user: curr_user,
                                              registration_item: item,
                                              materialized_at: Time.current)
      tutorial.members << curr_user
    end

    let(:component) { described_class.new(lecture: lecture, group_type: :tutorials) }

    it "renders" do
      render_inline(component)
      expect(rendered_content).to include("Fresh User")
    end

    it "returns only fresh candidates (never materialized, not on lecture roster)" do
      expect(component.candidates).to include(fresh_user)
      expect(component.candidates).not_to include(prev_user, curr_user)
    end

    it "excludes users already on lecture roster" do
      # Add fresh_user to lecture roster manually
      lecture.members << fresh_user

      # Should no longer appear in candidates
      expect(component.candidates).not_to include(fresh_user)
    end

    it "excludes users allocated to non-propagating cohorts" do
      cohort = create(:cohort, context: lecture, propagate_to_lecture: false)
      cohort_item = create(:registration_item, registration_campaign: campaign,
                                               registerable: cohort)
      cohort_user = create(:user, email: "cohort@example.com", name: "Cohort User")

      # User registered and was allocated to non-propagating cohort
      create(:registration_user_registration, registration_campaign: campaign,
                                              user: cohort_user,
                                              registration_item: cohort_item,
                                              materialized_at: Time.current)
      cohort.members << cohort_user

      # Should not appear in candidates (materialized_at is set)
      expect(component.candidates).not_to include(cohort_user)
    end

    describe "#add_member_path" do
      before { render_inline(component) }

      it "returns correct path for tutorial" do
        path = component.add_member_path(tutorial, fresh_user)
        expect(path)
          .to eq(Rails.application.routes.url_helpers
          .add_member_tutorial_path(tutorial,
                                    user_id: fresh_user.id, tab: "enrollment",
                                    active_tab: "enrollment",
                                    group_type: :tutorials,
                                    frame_id: "roster_maintenance_tutorials"))
      end

      it "returns correct path for talk" do
        seminar = create(:seminar)
        talk = create(:talk, lecture: seminar)
        path = component.add_member_path(talk, fresh_user)
        expect(path)
          .to eq(Rails.application.routes.url_helpers
          .add_member_talk_path(talk,
                                user_id: fresh_user.id, tab: "enrollment",
                                active_tab: "enrollment",
                                group_type: :tutorials,
                                frame_id: "roster_maintenance_tutorials"))
      end
    end

    describe "#candidate_info" do
      before { render_inline(component) }

      it "returns correct info" do
        info = component.candidate_info(fresh_user)
        expect(info.first[:campaign_title]).to eq(campaign.description)
        expect(info.first[:wishes]).to eq(tutorial.title)
      end
    end

    it "lists available groups" do
      expect(component.available_groups).to include(tutorial)
    end

    describe "#overbooked?" do
      it "returns false if group has no capacity" do
        tutorial.update(capacity: nil)
        expect(component.overbooked?(tutorial)).to be(false)
      end

      it "returns false if group is not full" do
        tutorial.update(capacity: 10)
        expect(component.overbooked?(tutorial)).to be(false)
      end

      it "returns true if group is full" do
        tutorial.update(capacity: 1)
        expect(component.overbooked?(tutorial)).to be(true)
      end

      it "returns true if group is over capacity" do
        tutorial.update(capacity: 0)
        expect(component.overbooked?(tutorial)).to be(true)
      end
    end
  end

  context "when group_type is talks" do
    let(:lecture) { create(:seminar) }
    let(:talk) { create(:talk, lecture: lecture) }
    let(:component) { described_class.new(lecture: lecture, group_type: :talks) }

    before do
      # We need a campaign for talks to have candidates
      talk_campaign = create(:registration_campaign, campaignable: lecture, status: :completed)
      talk_item = create(:registration_item, registration_campaign: talk_campaign,
                                             registerable: talk)
      create(:registration_user_registration, registration_campaign: talk_campaign,
                                              user: fresh_user, registration_item: talk_item)
    end

    it "renders" do
      render_inline(component)
      expect(rendered_content).to include("Fresh User")
    end

    it "lists available groups" do
      expect(component.available_groups).to include(talk)
    end
  end

  context "when group_type is invalid" do
    let(:lecture) { create(:lecture) }
    let(:component) { described_class.new(lecture: lecture, group_type: :invalid) }

    it "does not render" do
      render_inline(component)
      expect(rendered_content).to be_empty
    end
  end

  context "when group_type is an array" do
    let(:lecture) { create(:lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture, status: :completed) }
    let!(:item) do
      create(:registration_item, registration_campaign: campaign, registerable: tutorial)
    end

    before do
      create(:registration_user_registration, registration_campaign: campaign, user: fresh_user,
                                              registration_item: item, materialized_at: nil)
    end

    let(:component) { described_class.new(lecture: lecture, group_type: [:tutorials, :cohorts]) }

    it "renders" do
      render_inline(component)
      expect(rendered_content).to include("Fresh User")
    end

    it "lists available groups" do
      expect(component.available_groups).to include(tutorial)
    end
  end
end
