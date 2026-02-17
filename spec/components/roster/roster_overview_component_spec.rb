require "rails_helper"

RSpec.describe(RosterOverviewComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  # Default group_type is :all
  let(:component) { described_class.new(lecture: lecture) }

  describe "#sections" do
    context "with tutorials" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }

      it "places tutorials in the enrollment section" do
        sections = component.sections
        main_section = sections.first

        expect(main_section[:title]).to eq(I18n.t("roster.cohorts.with_lecture_enrollment_title"))
        expect(main_section[:items]).to include(tutorial)
      end
    end

    context "with talks" do
      let(:lecture) { create(:seminar) }
      let!(:talk) { create(:talk, lecture: lecture) }

      it "places talks in the enrollment section" do
        sections = component.sections
        main_section = sections.first

        expect(main_section[:title]).to eq(I18n.t("roster.cohorts.with_lecture_enrollment_title"))
        expect(main_section[:items]).to include(talk)
      end
    end

    context "with cohorts" do
      let!(:enrolled_cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }
      let!(:isolated_cohort) { create(:cohort, context: lecture, propagate_to_lecture: false) }

      it "places enrolled cohorts in the enrollment section" do
        sections = component.sections
        main_section = sections.find do |s|
          s[:title] == I18n.t("roster.cohorts.with_lecture_enrollment_title")
        end

        expect(main_section).to be_present
        expect(main_section[:items]).to include(enrolled_cohort)
        expect(main_section[:items]).not_to include(isolated_cohort)
      end

      it "places isolated cohorts in the without enrollment section" do
        sections = component.sections
        iso_section = sections.find do |s|
          s[:title] == I18n.t("roster.cohorts.without_lecture_enrollment_title")
        end

        expect(iso_section).to be_present
        expect(iso_section[:items]).to include(isolated_cohort)
        expect(iso_section[:items]).not_to include(enrolled_cohort)
      end
    end

    context "logic when filtering by group_type" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:enrolled_cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }

      it "only shows requested types" do
        # Only tutorials
        comp = described_class.new(lecture: lecture, group_type: :tutorials)
        sections = comp.sections
        main_items = sections.flat_map { |s| s[:items] }

        expect(main_items).to include(tutorial)
        expect(main_items).not_to include(enrolled_cohort)
      end
    end
  end

  describe "#actions" do
    it "includes Create Tutorial action in enrollment section" do
      sections = component.sections
      actions = sections.first[:actions]

      expect(actions).to include(include(text: Tutorial.model_name.human))
    end

    it "includes Create Enrolled Cohort action in enrollment section" do
      sections = component.sections
      actions = sections.first[:actions]

      expect(actions).to include(include(text: I18n.t("roster.group_category.flexible_group")))
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
  end

  describe "#active_campaign_for" do
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture, status: :draft) }

    before do
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

    it "caches campaign lookups to avoid N+1 queries" do
      campaign = create(:registration_campaign, campaignable: lecture, status: :draft)
      create(:registration_policy, :institutional_email,
             registration_campaign: campaign, active: true)
      campaign.update!(status: :completed)
      create(:registration_item, registerable: item, registration_campaign: campaign)

      # First call should populate the cache
      result1 = component.bypasses_campaign_policy?(item, "add_only")
      expect(result1).to be(true)

      # Verify the cache was populated
      cache_key = "#{item.class.name}-#{item.id}"
      expect(component.instance_variable_get(:@last_campaign_cache)).to have_key(cache_key)

      # Second call should use the cached value and return same result
      result2 = component.bypasses_campaign_policy?(item, "add_only")
      expect(result2).to eq(result1)

      # Cache should still contain the same campaign object
      cached_campaign = component.instance_variable_get(:@last_campaign_cache)[cache_key]
      expect(cached_campaign).to eq(campaign)
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
