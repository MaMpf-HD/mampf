require "rails_helper"

RSpec.describe(RosterCandidatesComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:campaign) { create(:registration_campaign, campaignable: lecture, status: :completed) }
  let!(:item) do
    create(:registration_item, registration_campaign: campaign, registerable: tutorial)
  end

  let(:fresh_user) { create(:user, email: "fresh@example.com", name: "Fresh User") }
  let(:prev_user) { create(:user, email: "prev@example.com", name: "Prev User") }
  let(:curr_user) { create(:user, email: "curr@example.com", name: "Curr User") }

  before do
    # Fresh user: Registered, never assigned
    create(:registration_user_registration, registration_campaign: campaign, user: fresh_user,
                                            registration_item: item, materialized_at: nil)

    # Previously assigned user: Registered, materialized, but currently NOT in tutorial
    create(:registration_user_registration, registration_campaign: campaign, user: prev_user,
                                            registration_item: item, materialized_at: Time.current)

    # Currently assigned user: Registered, materialized, AND in tutorial
    create(:registration_user_registration, registration_campaign: campaign, user: curr_user,
                                            registration_item: item, materialized_at: Time.current)
    tutorial.members << curr_user
  end

  context "when group_type is tutorials" do
    let(:component) { described_class.new(lecture: lecture, group_type: :tutorials) }

    it "renders" do
      render_inline(component)
      expect(rendered_content).to include("Fresh User")
    end

    it "returns correct candidates" do
      expect(component.candidates).to include(fresh_user, prev_user)
      expect(component.candidates).not_to include(curr_user)
    end

    it "identifies fresh candidates" do
      expect(component.fresh_candidates).to include(fresh_user)
      expect(component.fresh_candidates).not_to include(prev_user)
    end

    it "identifies previously assigned candidates" do
      expect(component.previously_assigned_candidates).to include(prev_user)
      expect(component.previously_assigned_candidates).not_to include(fresh_user)
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
    let(:component) { described_class.new(lecture: lecture, group_type: :invalid) }

    it "does not render" do
      render_inline(component)
      expect(rendered_content).to be_empty
    end
  end
end
