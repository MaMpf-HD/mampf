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
        expect(groups.pluck(:type)).to contain_exactly(:tutorials, :talks)
      end
    end

    context "when group_type is :tutorials" do
      let(:component) { described_class.new(lecture: lecture, group_type: :tutorials) }

      it "returns only tutorials" do
        groups = component.groups
        expect(groups.pluck(:type)).to contain_exactly(:tutorials)
      end
    end

    context "when group_type is :talks" do
      let(:component) { described_class.new(lecture: lecture, group_type: :talks) }

      it "returns only talks" do
        groups = component.groups
        expect(groups.pluck(:type)).to contain_exactly(:talks)
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
    let(:helpers) { double("helpers") }

    before do
      allow(component).to receive(:helpers).and_return(helpers)
    end

    it "returns tutorial roster path for a Tutorial" do
      tutorial = create(:tutorial, lecture: lecture)
      allow(helpers).to receive(:tutorial_roster_path)
        .with(tutorial).and_return("/tutorials/#{tutorial.id}/roster")
      expect(component.group_path(tutorial)).to eq("/tutorials/#{tutorial.id}/roster")
    end

    it "returns talk roster path for a Talk" do
      talk = create(:talk, lecture: lecture)
      allow(helpers).to receive(:talk_roster_path).with(talk).and_return("/talks/#{talk.id}/roster")
      expect(component.group_path(talk)).to eq("/talks/#{talk.id}/roster")
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
