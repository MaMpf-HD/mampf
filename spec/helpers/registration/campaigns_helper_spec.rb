require "rails_helper"

RSpec.describe(Registration::CampaignsHelper, type: :helper) do
  let(:campaign) { create(:registration_campaign, status: :draft) }
  let(:lecture) { create(:lecture) }

  describe "#email_domain" do
    it "extracts the domain correctly" do
      expect(helper.email_domain("test@example.com")).to eq("example.com")
      expect(helper.email_domain("no_at_sign.com")).to eq("no_at_sign.com")
      expect(helper.email_domain(nil)).to be_nil
    end
  end

  describe "#campaign_badge_color" do
    it "returns the correct color sequence based on status" do
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :draft))).to eq("secondary")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :open))).to eq("success")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :closed))).to eq("warning")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :processing))).to eq("info")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :completed))).to eq("dark")
    end
  end

  describe "ID generation methods" do
    it "#campaign_header_frame_id" do
      expect(helper.campaign_header_frame_id(campaign)).to eq("campaign_header_frame_#{campaign.id}")
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
      p1 = create(:registration_policy, registration_campaign: campaign, kind: :student_performance, position: 1)
      p2 = create(:registration_policy, registration_campaign: campaign, kind: :institutional_email, position: 2)
      
      expect(helper.policy_kinds_summary(campaign)).to eq("#{I18n.t("registration.policy.kinds.student_performance")}, #{I18n.t("registration.policy.kinds.institutional_email")}")
    end
  end

  describe "#sorted_preference_counts" do
    it "sorts preferences pushing :forced to the end" do
      stats = double("Stats", preference_counts: { :forced => 5, 2 => 10, 1 => 20 })
      expect(helper.sorted_preference_counts(stats)).to eq([[1, 20], [2, 10], [:forced, 5]])
    end
  end

  describe "#rank_color" do
    it "maps correctly" do
      expect(helper.rank_color(:forced)).to eq(:danger)
      expect(helper.rank_color(1)).to eq(:success)
      expect(helper.rank_color(2)).to eq(:primary)
      expect(helper.rank_color(3)).to eq(:secondary)
      expect(helper.rank_color(99)).to eq(:secondary)
    end
  end

  describe "#rank_label" do
    it "returns specific label for forced" do
      expect(helper.rank_label(:forced)).to eq(I18n.t("registration.allocation.stats.forced"))
    end

    it "returns parameterized label for integer ranks" do
      expect(helper.rank_label(3)).to eq(I18n.t("registration.allocation.stats.rank_label", rank: 3))
    end
  end

  describe "#campaign_close_confirmation" do
    it "returns early confirmation when deadline is future" do
      campaign.registration_deadline = 1.day.from_now
      expect(helper.campaign_close_confirmation(campaign)).to eq(I18n.t("registration.campaign.confirmations.close_early"))
    end

    it "returns normal confirmation when deadline passes" do
      campaign.registration_deadline = 1.day.ago
      expect(helper.campaign_close_confirmation(campaign)).to eq(I18n.t("registration.campaign.confirmations.close"))
    end
  end

  describe "#no_campaign_registerables" do
    it "delegates to Rosters::NoCampaignRegisterablesQuery" do
      query = double("Query")
      expect(Rosters::NoCampaignRegisterablesQuery).to receive(:new).with(lecture).and_return(query)
      expect(query).to receive(:call).and_return([])
      expect(helper.no_campaign_registerables(lecture)).to eq([])
    end
  end

  describe "#campaign_open_confirmation" do
    it "returns base confirmation string" do
      expect(helper.campaign_open_confirmation(campaign)).to eq(I18n.t("registration.campaign.confirmations.open"))
    end

    it "appends unlimited items warning if there are items missing capacity" do
      create(:registration_item, registration_campaign: campaign, capacity: nil)
      create(:registration_item, registration_campaign: campaign, capacity: 10)
      
      expected = I18n.t("registration.campaign.confirmations.open") + "\n\n" + I18n.t("registration.campaign.warnings.unlimited_items")
      expect(helper.campaign_open_confirmation(campaign)).to eq(expected)
    end
  end

  describe "buttons" do
    it "#campaign_finalize_confirmation returns correct t" do
      expect(helper.campaign_finalize_confirmation).to eq(I18n.t("registration.campaign.confirmations.finalize"))
    end

    describe "#finalize_campaign_button" do
      it "returns a button form" do
        html = helper.finalize_campaign_button(campaign, size: "btn-sm", disabled: true)
        expect(html).to include("btn btn-danger btn-sm\" disabled=\"disabled\"")
        expect(html).to include(I18n.t("registration.campaign.actions.finalize"))
      end
    end

    describe "#allocate_campaign_button" do
      it "returns allocate button if no previous calculation" do
        campaign.last_allocation_calculated_at = nil
        html = helper.allocate_campaign_button(campaign, size: "btn-lg")
        expect(html).to include("btn btn-primary btn-lg")
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
