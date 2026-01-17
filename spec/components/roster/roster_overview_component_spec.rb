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

      let!(:fresh_tutorial) do
        create(:tutorial, lecture: lecture, title: "C Fresh", skip_campaigns: false)
      end

      let!(:skip_campaigns_tutorial) do
        create(:tutorial, lecture: lecture, title: "D Skip Campaigns", skip_campaigns: true)
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
        .with(item, { self_materialization_mode: "add_only", group_type: :all })
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

  describe "#primary_status" do
    let(:item) { create(:tutorial, lecture: lecture) }

    context "with active campaign" do
      let(:campaign) { build(:registration_campaign, status: :open) }

      it "returns campaign status text" do
        expect(component.primary_status(item, campaign))
          .to eq(I18n.t("roster.status_texts.campaign_open"))
      end
    end

    context "with completed campaign" do
      before do
        campaign = create(:registration_campaign, campaignable: lecture, status: :completed)
        create(:registration_item, registerable: item, registration_campaign: campaign)
      end

      it "returns post-campaign status without self-enrollment" do
        expect(component.primary_status(item, nil))
          .to eq(I18n.t("roster.status_texts.post_campaign"))
      end

      it "returns post-campaign status with self-enrollment" do
        item.update(self_materialization_mode: :add_only)
        expect(component.primary_status(item, nil))
          .to eq("#{I18n.t("roster.status_texts.post_campaign")} " \
                 "(#{I18n.t("roster.status_texts.self_enrollment")})")
      end

      it "returns post-campaign status with self-enrollment and policy warning" do
        policy_item = create(:tutorial, lecture: lecture)
        campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign, active: true)
        campaign.update!(status: :completed)
        create(:registration_item, registerable: policy_item, registration_campaign: campaign)
        policy_item.update(self_materialization_mode: :add_only)

        expect(component.primary_status(policy_item, nil))
          .to include(I18n.t("roster.status_texts.post_campaign"))
          .and(include(I18n.t("roster.status_texts.self_enrollment")))
          .and(include(I18n.t("roster.status_texts.no_policy_enforcement")))
      end
    end

    context "with skip_campaigns" do
      before do
        item.update(skip_campaigns: true)
      end

      it "returns direct management status without self-enrollment" do
        expect(component.primary_status(item, nil))
          .to eq(I18n.t("roster.status_texts.direct_management"))
      end

      it "returns direct management status with self-enrollment" do
        item.update(self_materialization_mode: :add_only)
        expect(component.primary_status(item, nil))
          .to eq("#{I18n.t("roster.status_texts.direct_management")} " \
                 "(#{I18n.t("roster.status_texts.self_enrollment")})")
      end
    end

    context "brand new item" do
      it "returns awaiting setup status" do
        expect(component.primary_status(item, nil))
          .to eq(I18n.t("roster.status_texts.awaiting_setup"))
      end
    end
  end

  describe "#bypasses_campaign_policy?" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns false for disabled target mode" do
      expect(component.bypasses_campaign_policy?(item, "disabled")).to be(false)
    end

    it "returns false without completed campaign" do
      expect(component.bypasses_campaign_policy?(item, "add_only")).to be(false)
    end

    it "returns false when campaign has no policy" do
      campaign = create(:registration_campaign, campaignable: lecture, status: :completed)
      create(:registration_item, registerable: item, registration_campaign: campaign)

      expect(component.bypasses_campaign_policy?(item, "add_only")).to be(false)
    end

    it "returns true when target mode would bypass campaign policy" do
      campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
      create(:registration_policy, :institutional_email,
             registration_campaign: campaign, active: true)
      campaign.update!(status: :completed)
      create(:registration_item, registerable: item, registration_campaign: campaign)

      expect(component.bypasses_campaign_policy?(item, "add_only")).to be(true)
    end
  end

  describe "#policy_bypass_warning_data" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns nil when no policy bypass" do
      expect(component.policy_bypass_warning_data(item, "disabled")).to be_nil
    end

    it "returns warning data when bypassing policy" do
      campaign = create(:registration_campaign, campaignable: lecture,
                                                status: :draft,
                                                description: "Test Campaign")
      create(:registration_policy, :institutional_email,
             registration_campaign: campaign, active: true)
      campaign.update!(status: :completed)
      create(:registration_item, registerable: item, registration_campaign: campaign)

      data = component.policy_bypass_warning_data(item, "add_only")
      expect(data).to include(
        policy_name: I18n.t("registration.policy.kinds.institutional_email"),
        campaign_name: "Test Campaign"
      )
    end
  end

  describe "#campaign_has_policies?" do
    it "returns false when campaign is nil" do
      expect(component.campaign_has_policies?(nil)).to be(false)
    end

    it "returns false when campaign has no policies" do
      campaign = create(:registration_campaign, campaignable: lecture)
      expect(component.campaign_has_policies?(campaign)).to be(false)
    end

    it "returns true when campaign has policies" do
      campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
      create(:registration_policy, :institutional_email,
             registration_campaign: campaign, active: true)
      expect(component.campaign_has_policies?(campaign)).to be(true)
    end

    it "works with loaded associations" do
      campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
      create(:registration_policy, :institutional_email,
             registration_campaign: campaign, active: true)

      campaign.registration_policies.load

      expect(component.campaign_has_policies?(campaign)).to be(true)
    end
  end

  describe "#self_enrollment_badge_data" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns correct data for disabled mode" do
      item.update(self_materialization_mode: :disabled)
      data = component.self_enrollment_badge_data(item)

      expect(data[:icon]).to eq("bi-person-fill")
      expect(data[:text]).to eq("")
      expect(data[:has_warning]).to be(false)
    end

    it "returns correct data for add_only mode" do
      item.update(self_materialization_mode: :add_only)
      data = component.self_enrollment_badge_data(item)

      expect(data[:icon]).to eq("bi-person-fill")
      expect(data[:text]).to eq("+")
      expect(data[:css_class]).to eq("bg-light text-success border border-success")
      expect(data[:has_warning]).to be(false)
    end

    it "returns correct data for remove_only mode" do
      item.update(self_materialization_mode: :remove_only)
      data = component.self_enrollment_badge_data(item)

      expect(data[:icon]).to eq("bi-person-fill")
      expect(data[:text]).to eq("−")
      expect(data[:has_warning]).to be(false)
    end

    it "returns correct data for add_and_remove mode" do
      item.update(self_materialization_mode: :add_and_remove)
      data = component.self_enrollment_badge_data(item)

      expect(data[:icon]).to eq("bi-person-fill")
      expect(data[:text]).to eq("±")
      expect(data[:has_warning]).to be(false)
    end

    it "includes warning when bypassing campaign policy" do
      campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
      create(:registration_policy, :institutional_email,
             registration_campaign: campaign, active: true)
      campaign.update!(status: :completed)
      create(:registration_item, registerable: item, registration_campaign: campaign)
      item.update(self_materialization_mode: :add_only)

      data = component.self_enrollment_badge_data(item)

      expect(data[:has_warning]).to be(true)
      expect(data[:tooltip]).to include(I18n.t("roster.status_texts.no_policy_enforcement"))
    end
  end
end
