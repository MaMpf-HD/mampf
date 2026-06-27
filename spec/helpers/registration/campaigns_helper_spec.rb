require "rails_helper"

RSpec.describe(Registration::CampaignsHelper, type: :helper) do
  let(:campaign) { create(:registration_campaign, status: :draft) }

  describe "#email_domain" do
    it "extracts the domain correctly" do
      expect(helper.email_domain("test@example.com")).to eq("example.com")
      expect(helper.email_domain("no_at_sign.com")).to eq("no_at_sign.com")
      expect(helper.email_domain(nil)).to be_nil
    end
  end

  describe "#campaign_badge_color" do
    it "returns the correct color sequence based on status" do
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :draft)))
        .to eq("secondary")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :open)))
        .to eq("success")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :closed)))
        .to eq("warning")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :processing)))
        .to eq("info")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :completed)))
        .to eq("dark")
    end
  end

  describe "ID generation methods" do
    it "#campaign_header_frame_id" do
      expect(helper.campaign_header_frame_id(campaign))
        .to eq("campaign_header_frame_#{campaign.id}")
    end

    it "#campaign_actions_id" do
      expect(helper.campaign_actions_id(campaign)).to eq("campaign_actions_#{campaign.id}")
    end

    it "#campaign_policy_form_frame_id" do
      expect(helper.campaign_policy_form_frame_id(campaign)).to eq("policy_form_#{campaign.id}")
    end
  end

  describe "#policy_kinds_summary" do
    it "returns joined translations" do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :student_performance, position: 1)
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email, position: 2)

      expect(helper.policy_kinds_summary(campaign))
        .to eq(
          "#{I18n.t("registration.policy.kinds.student_performance")}, " \
          "#{I18n.t("registration.policy.kinds.institutional_email")}"
        )
    end
  end

  describe "#sorted_preference_counts" do
    it "sorts preferences pushing :forced to the end" do
      stats = double("Stats", preference_counts: { :forced => 5, 2 => 10, 1 => 20 })
      expect(helper.sorted_preference_counts(stats)).to eq([[1, 20], [2, 10], [:forced, 5]])
    end
  end

  describe "summary item helpers" do
    it "maps summary item kinds to translation keys" do
      expect(helper.allocation_summary_item_translation_key(kind: :assigned))
        .to eq("registration.allocation.stats.assigned_inline")
    end

    it "maps summary item kinds to css classes" do
      expect(helper.allocation_summary_item_css_class(kind: :currently_rejected, count: 1))
        .to eq("text-danger fw-medium")
    end

    it "uses muted styling for zero unassigned users" do
      expect(helper.allocation_summary_item_css_class(kind: :unassigned, count: 0))
        .to eq("text-muted fw-medium")
    end

    it "uses danger styling for positive unassigned users" do
      expect(helper.allocation_summary_item_css_class(kind: :unassigned, count: 1))
        .to eq("text-danger fw-medium")
    end
  end

  describe "#allocation_progress_bar" do
    it "renders an allocation-specific progress bar" do
      html = helper.allocation_progress_bar(
        50,
        100,
        bar_class: "allocation-progress-bar--first"
      )

      expect(html).to include("allocation-progress-bar allocation-progress-bar--first")
      expect(html).to include('style="width: 50.0%"')
      expect(html).to include('aria-valuenow="50"')
    end
  end

  describe "#allocation_rank_bar_class" do
    it "maps correctly" do
      expect(helper.allocation_rank_bar_class(:forced))
        .to eq("allocation-progress-bar--forced")
      expect(helper.allocation_rank_bar_class(1))
        .to eq("allocation-progress-bar--first")
      expect(helper.allocation_rank_bar_class(2))
        .to eq("allocation-progress-bar--second")
      expect(helper.allocation_rank_bar_class(3))
        .to eq("allocation-progress-bar--other")
      expect(helper.allocation_rank_bar_class(99))
        .to eq("allocation-progress-bar--other")
    end
  end

  describe "#allocation_utilization_bar_class" do
    it "maps percentages to utilization classes" do
      expect(helper.allocation_utilization_bar_class(40))
        .to eq("allocation-progress-bar--utilization-low")
      expect(helper.allocation_utilization_bar_class(85))
        .to eq("allocation-progress-bar--utilization-mid")
      expect(helper.allocation_utilization_bar_class(110))
        .to eq("allocation-progress-bar--utilization-high")
    end
  end

  describe "#rank_label" do
    it "returns specific label for forced" do
      expect(helper.rank_label(:forced)).to eq(I18n.t("registration.allocation.stats.forced"))
    end

    it "returns parameterized label for integer ranks" do
      expect(helper.rank_label(3)).to eq(I18n.t("registration.allocation.stats.rank_label",
                                                rank: 3))
    end
  end

  describe "#campaign_close_confirmation" do
    it "returns early confirmation when deadline is future" do
      campaign.registration_deadline = 1.day.from_now
      expect(helper.campaign_close_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.close_early"))
    end

    it "returns normal confirmation when deadline passes" do
      campaign.registration_deadline = 1.day.ago
      expect(helper.campaign_close_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.close"))
    end
  end

  describe "#campaign_open_confirmation" do
    it "returns base confirmation string" do
      expect(helper.campaign_open_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.open"))
    end

    it "appends unlimited items warning if there are items missing capacity" do
      create(:registration_item, registration_campaign: campaign, capacity: nil)
      create(:registration_item, registration_campaign: campaign, capacity: 10)

      expected = [I18n.t("registration.campaign.confirmations.open"),
                  I18n.t("registration.campaign.warnings.unlimited_items")].join("\n\n")
      expect(helper.campaign_open_confirmation(campaign)).to eq(expected)
    end
  end

  describe "buttons" do
    it "#campaign_finalize_confirmation returns correct t" do
      expect(helper.campaign_finalize_confirmation)
        .to eq(I18n.t("registration.campaign.confirmations.finalize"))
    end

    describe "#finalize_campaign_button" do
      it "returns a button form" do
        html = helper.finalize_campaign_button(campaign, size: "btn-sm", disabled: true)
        expect(html).to include("btn allocation-action-primary btn-sm\" disabled=\"disabled\"")
        expect(html).to include(I18n.t("registration.campaign.actions.finalize"))
      end
    end

    describe "#allocate_campaign_button" do
      it "returns allocate button if no previous calculation" do
        campaign.last_allocation_calculated_at = nil
        html = helper.allocate_campaign_button(campaign, size: "btn-lg")
        expect(html).to include("btn btn-outline-primary btn-lg")
        expect(html).to include(I18n.t("registration.campaign.actions.allocate"))
        expect(html).not_to include("turbo-confirm")
      end

      it "returns reallocate button with confirm if previous calculation" do
        campaign.last_allocation_calculated_at = Time.current
        html = helper.allocate_campaign_button(campaign)
        expect(html).to include(I18n.t("registration.campaign.actions.reallocate"))
        expect(html).to include("turbo-confirm")
        expect(html).to include(I18n.t("registration.campaign.confirmations.reallocate"))
      end
    end
  end
end
