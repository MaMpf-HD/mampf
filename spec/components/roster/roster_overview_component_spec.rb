require "rails_helper"

RSpec.describe(RosterOverviewComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:component) { described_class.new(lecture: lecture) }

  describe "#groups" do
    context "with tutorials" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }

      it "returns tutorials when group_type is :all" do
        groups = component.groups
        expect(groups.pluck(:type)).to contain_exactly(:tutorials, :cohorts)
      end

      it "returns tutorials when group_type is :tutorials" do
        component = described_class.new(lecture: lecture, group_type: :tutorials)
        groups = component.groups
        expect(groups.pluck(:type)).to contain_exactly(:tutorials)
      end
    end

    context "with talks" do
      let(:lecture) { create(:seminar) }
      let!(:talk) { create(:talk, lecture: lecture) }

      it "returns talks when group_type is :all" do
        groups = component.groups
        expect(groups.pluck(:type)).to contain_exactly(:talks, :cohorts)
      end

      it "returns talks when group_type is :talks" do
        component = described_class.new(lecture: lecture, group_type: :talks)
        groups = component.groups
        expect(groups.pluck(:type)).to contain_exactly(:talks)
      end
    end

    context "sorting" do
      context "tutorials" do
        let!(:locked_tutorial) do
          t = create(:tutorial, lecture: lecture, title: "A Locked")
          allow(t).to receive(:in_real_campaign?).and_return(true)
          allow(t).to receive(:manual_roster_mode?).and_return(false)
          t
        end

        let!(:manual_tutorial) do
          t = create(:tutorial, lecture: lecture, title: "B Manual", manual_roster_mode: true)
          allow(t).to receive(:roster_empty?).and_return(true)
          t
        end

        let!(:standard_tutorial) do
          t = create(:tutorial, lecture: lecture, title: "C Standard", manual_roster_mode: false)
          allow(t).to receive(:in_real_campaign?).and_return(false)
          t
        end

        it "sorts locked items first, then switchable items" do
          groups = component.groups
          tutorials = groups.find { |g| g[:type] == :tutorials }[:items]

          expect(tutorials.first).to eq(locked_tutorial)

          relevant_tutorials = tutorials.select do |t|
            [manual_tutorial, standard_tutorial].include?(t)
          end
          expect(relevant_tutorials).to eq([manual_tutorial, standard_tutorial])
        end
      end

      context "talks" do
        let(:lecture) { create(:seminar) }

        it "sorts talks by position" do
          talk1 = create(:talk, lecture: lecture, position: 2)
          talk2 = create(:talk, lecture: lecture, position: 1)

          component = described_class.new(lecture: lecture, group_type: :talks)
          groups = component.groups
          talks = groups.find { |g| g[:type] == :talks }[:items]

          expect(talks).to eq([talk2, talk1])
        end
      end
    end
  end

  describe "#participants" do
    let!(:tutorial) { create(:tutorial, lecture: lecture) }
    let!(:users) { create_list(:user, 3) }

    before do
      users.each { |u| create(:lecture_membership, lecture: lecture, user: u) }
    end

    it "returns the lecture memberships" do
      expect(component.participants.size).to eq(3)
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
      expect(component.group_type_title).to eq(I18n.t("roster.tabs.group_maintenance"))
    end

    it "returns the default title for array" do
      component = described_class.new(lecture: lecture, group_type: [:tutorials, :talks])
      expect(component.group_type_title).to eq(I18n.t("roster.tabs.group_maintenance"))
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

    context "with seminar" do
      let(:lecture) { create(:seminar) }

      it "returns talk roster path for a Talk" do
        talk = create(:talk, lecture: lecture)
        allow(helpers).to receive(:talk_roster_path).with(talk)
                                                    .and_return("/talks/#{talk.id}/roster")
        expect(component.group_path(talk)).to eq("/talks/#{talk.id}/roster")
      end
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

  describe "#campaign_badge_props" do
    let(:draft_campaign) { build(:registration_campaign, status: :draft) }
    let(:running_campaign) { build(:registration_campaign, status: :open) }

    it "returns draft badge properties for draft campaign" do
      props = component.campaign_badge_props(draft_campaign)
      expect(props[:text]).to eq(I18n.t("roster.campaign_draft"))
      expect(props[:css_class]).to include("bg-secondary")
    end

    it "returns running badge properties for running campaign" do
      props = component.campaign_badge_props(running_campaign)
      expect(props[:text]).to eq(I18n.t("roster.campaign_running"))
      expect(props[:css_class]).to include("bg-info")
    end
  end

  describe "#show_manual_mode_switch?" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns true if manual mode can be disabled" do
      allow(item).to receive(:manual_roster_mode?).and_return(true)
      allow(item).to receive(:can_disable_manual_mode?).and_return(true)
      expect(component.show_manual_mode_switch?(item)).to be(true)
    end

    it "returns true if manual mode can be enabled" do
      allow(item).to receive(:manual_roster_mode?).and_return(false)
      allow(item).to receive(:can_enable_manual_mode?).and_return(true)
      expect(component.show_manual_mode_switch?(item)).to be(true)
    end

    it "returns false otherwise" do
      allow(item).to receive(:manual_roster_mode?).and_return(true)
      allow(item).to receive(:can_disable_manual_mode?).and_return(false)
      expect(component.show_manual_mode_switch?(item)).to be(false)
    end
  end

  describe "#toggle_manual_mode_path" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns the correct path" do
      allow(Rails.application.routes.url_helpers).to receive(:tutorial_roster_path)
        .with(item).and_return("/path/to/roster")

      expect(component.toggle_manual_mode_path(item)).to eq("/path/to/roster")
    end
  end
end
