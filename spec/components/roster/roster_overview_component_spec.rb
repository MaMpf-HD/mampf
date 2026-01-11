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
      let!(:completed_campaign_tutorial) do
        t = create(:tutorial, lecture: lecture, title: "B Completed Campaign")
        campaign = create(:registration_campaign, campaignable: lecture, status: :completed)
        create(:registration_item, registerable: t, registration_campaign: campaign)
        t
      end

      let!(:active_campaign_tutorial) do
        t = create(:tutorial, lecture: lecture, title: "A Active Campaign")
        campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
        create(:registration_item, registerable: t, registration_campaign: campaign)
        t
      end

      let!(:skip_campaigns_tutorial) do
        create(:tutorial, lecture: lecture, title: "D Skip Campaigns", skip_campaigns: true)
      end

      let!(:fresh_tutorial) do
        create(:tutorial, lecture: lecture, title: "C Fresh", skip_campaigns: false)
      end

      it "sorts completed campaigns first, then others, each subgroup sorted by title" do
        groups = component.groups
        tutorials = groups.find { |g| g[:type] == :tutorials }[:items]

        expect(tutorials.first).to eq(completed_campaign_tutorial)

        remaining = tutorials[1..]
        expect(remaining.map(&:title)).to eq([
                                               "A Active Campaign",
                                               "C Fresh",
                                               "D Skip Campaigns"
                                             ])
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
      # skip_campaigns? is false by default (assuming)
      # roster_empty? is true by default
      expect(component.show_campaign_running_badge?(tutorial, campaign)).to be(true)
    end

    it "returns false if manual roster mode" do
      allow(tutorial).to receive(:skip_campaigns?).and_return(true)
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

  describe "#show_skip_campaigns_switch?" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns true if skip_campaigns can be disabled" do
      allow(item).to receive(:skip_campaigns?).and_return(true)
      allow(item).to receive(:can_unskip_campaigns?).and_return(true)
      expect(component.show_skip_campaigns_switch?(item)).to be(true)
    end

    it "returns true if skip_campaigns can be enabled" do
      allow(item).to receive(:skip_campaigns?).and_return(false)
      allow(item).to receive(:can_skip_campaigns?).and_return(true)
      expect(component.show_skip_campaigns_switch?(item)).to be(true)
    end

    it "returns false otherwise" do
      allow(item).to receive(:skip_campaigns?).and_return(true)
      allow(item).to receive(:can_unskip_campaigns?).and_return(false)
      expect(component.show_skip_campaigns_switch?(item)).to be(false)
    end
  end

  describe "#toggle_skip_campaigns_path" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns the correct path" do
      allow(Rails.application.routes.url_helpers).to receive(:tutorial_roster_path)
        .with(item).and_return("/path/to/roster")

      expect(component.toggle_skip_campaigns_path(item)).to eq("/path/to/roster")
    end
  end

  describe "#update_self_materialization_path" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns the correct path without group_type" do
      allow(Rails.application.routes.url_helpers)
        .to receive(:tutorial_update_self_materialization_path)
        .with(item, { self_materialization_mode: "add_only" })
        .and_return("/path/to/self_materialization")

      expect(component.update_self_materialization_path(item, "add_only"))
        .to eq("/path/to/self_materialization")
    end

    it "returns the correct path with group_type parameter" do
      allow(Rails.application.routes.url_helpers)
        .to receive(:tutorial_update_self_materialization_path)
        .with(item, { self_materialization_mode: "add_only", group_type: :tutorials })
        .and_return("/path/to/self_materialization?group_type=tutorials")

      expect(component.update_self_materialization_path(item, "add_only", :tutorials))
        .to eq("/path/to/self_materialization?group_type=tutorials")
    end

    it "returns the correct path with array group_type parameter" do
      allow(Rails.application.routes.url_helpers)
        .to receive(:tutorial_update_self_materialization_path)
        .with(item, { self_materialization_mode: "add_only",
                      group_type: [:tutorials, :cohorts] })
        .and_return("/path/to/self_materialization?group_type[]=tutorials&group_type[]=cohorts")

      expect(component.update_self_materialization_path(item, "add_only",
                                                        [:tutorials, :cohorts]))
        .to eq("/path/to/self_materialization?group_type[]=tutorials&group_type[]=cohorts")
    end
  end

  describe "#update_self_materialization_path" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns the correct path without group_type" do
      allow(Rails.application.routes.url_helpers)
        .to receive(:tutorial_update_self_materialization_path)
        .with(item, { self_materialization_mode: "add_only" })
        .and_return("/path/to/self_materialization")

      expect(component.update_self_materialization_path(item, "add_only"))
        .to eq("/path/to/self_materialization")
    end

    it "returns the correct path with group_type parameter" do
      allow(Rails.application.routes.url_helpers)
        .to receive(:tutorial_update_self_materialization_path)
        .with(item, { self_materialization_mode: "add_only", group_type: :tutorials })
        .and_return("/path/to/self_materialization?group_type=tutorials")

      expect(component.update_self_materialization_path(item, "add_only", :tutorials))
        .to eq("/path/to/self_materialization?group_type=tutorials")
    end

    it "returns the correct path with array group_type parameter" do
      allow(Rails.application.routes.url_helpers)
        .to receive(:tutorial_update_self_materialization_path)
        .with(item, { self_materialization_mode: "add_only",
                      group_type: [:tutorials, :cohorts] })
        .and_return("/path/to/self_materialization?group_type[]=tutorials&group_type[]=cohorts")

      expect(component.update_self_materialization_path(item, "add_only",
                                                        [:tutorials, :cohorts]))
        .to eq("/path/to/self_materialization?group_type[]=tutorials&group_type[]=cohorts")
    end
  end
end
