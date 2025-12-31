require "rails_helper"

RSpec.describe(RosterOverviewComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:component) { described_class.new(lecture: lecture) }

  describe "#groups" do
    let!(:tutorial) { create(:tutorial, lecture: lecture) }
    let!(:talk) { create(:talk, lecture: lecture) }

    context "when group_type is :all" do
      it "returns both tutorials and talks" do
        groups = component.groups
        expect(groups.map { |g| g[:type] }).to contain_exactly(:tutorials, :talks)
      end
    end

    context "when group_type is :tutorials" do
      let(:component) { described_class.new(lecture: lecture, group_type: :tutorials) }

      it "returns only tutorials" do
        groups = component.groups
        expect(groups.map { |g| g[:type] }).to contain_exactly(:tutorials)
      end
    end

    context "when group_type is :talks" do
      let(:component) { described_class.new(lecture: lecture, group_type: :talks) }

      it "returns only talks" do
        groups = component.groups
        expect(groups.map { |g| g[:type] }).to contain_exactly(:talks)
      end
    end
  end

  describe "#total_participants" do
    let!(:tutorial) { create(:tutorial, lecture: lecture) }
    let!(:users) { create_list(:user, 3) }

    before do
      users.each { |u| tutorial.members << u }
    end

    it "returns the total count of participants" do
      expect(component.total_participants).to eq(3)
    end
  end

  describe "#total_capacity" do
    let!(:tutorial_1) { create(:tutorial, lecture: lecture, capacity: 10) }
    let!(:tutorial_2) { create(:tutorial, lecture: lecture, capacity: 20) }

    it "returns the sum of capacities" do
      expect(component.total_capacity).to eq(30)
    end

    context "when a group has nil capacity" do
      before { tutorial_2.update(capacity: nil) }

      it "returns nil" do
        expect(component.total_capacity).to be_nil
      end
    end
  end

  describe "#unassigned_count" do
    context "when group_type is :tutorials" do
      let(:component) { described_class.new(lecture: lecture, group_type: :tutorials) }
      let(:campaign) { instance_double(Registration::Campaign) }
      let(:user_ids) { [1, 2, 3] }

      before do
        allow(Registration::Campaign).to receive(:where).and_return(Registration::Campaign.all)
        allow(Registration::Campaign).to receive(:joins).and_return(Registration::Campaign.all)
        # We need to mock the chain: where(campaignable).joins(:registration_items).where(type).distinct
        # This is getting messy to mock ActiveRecord chains.
        # Let's try to create the records instead if possible, or use a simpler mock approach.
      end

      # Alternative: Mock the private method or the query result if possible.
      # But we can't easily mock private methods in the component without send.
      # Let's try to create a campaign.

      it "counts unassigned users" do
        # This test might be brittle if we don't set up the full registration machinery.
        # Let's skip deep integration testing of unassigned_users logic here and focus on the component logic.
        # We can mock the result of the query.

        relation = double("ActiveRecord::Relation")
        allow(Registration::Campaign).to receive(:where).with(campaignable: lecture).and_return(relation)
        allow(relation).to receive(:joins).with(:registration_items).and_return(relation)
        allow(relation).to receive(:where).with(registration_items: { registerable_type: "Tutorial" }).and_return(relation)
        allow(relation).to receive(:distinct).and_return([campaign])

        allow(campaign).to receive_message_chain(:unassigned_users, :pluck).and_return([1, 2])

        expect(component.unassigned_count).to eq(2)
      end
    end

    context "when group_type is :all" do
      it "returns 0" do
        expect(component.unassigned_count).to eq(0)
      end
    end
  end

  describe "#group_type_title" do
    it "returns the correct title for tutorials" do
      component = described_class.new(lecture: lecture, group_type: :tutorials)
      expect(component.group_type_title).to eq(I18n.t("roster.tabs.tutorial_maintenance"))
    end

    it "returns the correct title for talks" do
      component = described_class.new(lecture: lecture, group_type: :talks)
      expect(component.group_type_title).to eq(I18n.t("roster.tabs.talk_maintenance"))
    end

    it "returns the default title for all" do
      expect(component.group_type_title).to eq(I18n.t("roster.dashboard.title"))
    end
  end

  describe "#group_path" do
    it "returns tutorial roster path for a Tutorial" do
      tutorial = create(:tutorial, lecture: lecture)
      expect(component.group_path(tutorial)).to eq(Rails.application.routes.url_helpers.tutorial_roster_path(tutorial))
    end

    it "returns talk roster path for a Talk" do
      talk = create(:talk, lecture: lecture)
      expect(component.group_path(talk)).to eq(Rails.application.routes.url_helpers.talk_roster_path(talk))
    end
  end

  describe "#active_campaign_for" do
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture, status: :draft) }

    before do
      # Link campaign to tutorial via registration_item
      create(:registration_item, registration_campaign: campaign, registerable: tutorial)
      campaign.update(status: :open)
    end

    it "returns the active campaign" do
      expect(component.active_campaign_for(tutorial)).to eq(campaign)
    end
  end

  describe "#show_campaign_running_badge?" do
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign) }

    it "returns true when conditions are met" do
      # manual_roster_mode? is false by default (assuming)
      # roster_empty? is true by default
      expect(component.show_campaign_running_badge?(tutorial, campaign)).to be(true)
    end

    it "returns false if manual roster mode" do
      allow(tutorial).to receive(:manual_roster_mode?).and_return(true)
      expect(component.show_campaign_running_badge?(tutorial, campaign)).to be(false)
    end

    it "returns false if campaign is missing" do
      expect(component.show_campaign_running_badge?(tutorial, nil)).to be(false)
    end

    it "returns false if roster is not empty" do
      allow(tutorial).to receive(:roster_empty?).and_return(false)
      expect(component.show_campaign_running_badge?(tutorial, campaign)).to be(false)
    end
  end
end
