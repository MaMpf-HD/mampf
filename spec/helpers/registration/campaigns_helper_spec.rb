require "rails_helper"

# Missing top-level docstring, please formulate one yourself 😁
RSpec.describe(Registration::CampaignsHelper, type: :helper) do
  describe "#campaign_badge_color" do
    it "returns the correct color for each status" do
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

  describe "#campaign_item_type_label" do
    it "returns dash if no items" do
      campaign = build(:registration_campaign)
      expect(helper.campaign_item_type_label(campaign)).to eq("—")
    end

    it "returns translated type label" do
      campaign = create(:registration_campaign, :with_items)
      # Factory creates Tutorial items by default
      expect(helper.campaign_item_type_label(campaign))
        .to eq(I18n.t("registration.item.types.tutorial"))
    end
  end

  describe "#item_stats_label" do
    it "returns registrations for FCFS" do
      campaign = build(:registration_campaign, :first_come_first_served)
      expect(helper.item_stats_label(campaign))
        .to eq(I18n.t("registration.item.columns.registrations"))
    end

    it "returns registrations for processing" do
      campaign = build(:registration_campaign, :processing)
      expect(helper.item_stats_label(campaign))
        .to eq(I18n.t("registration.item.columns.registrations"))
    end

    it "returns registrations for completed" do
      campaign = build(:registration_campaign, :completed)
      expect(helper.item_stats_label(campaign))
        .to eq(I18n.t("registration.item.columns.registrations"))
    end

    it "returns first choice for preference based open/closed" do
      campaign = build(:registration_campaign, :preference_based, status: :open)
      expect(helper.item_stats_label(campaign))
        .to eq(I18n.t("registration.item.columns.first_choice"))
    end
  end

  describe "#item_stats_count" do
    let(:item) { create(:registration_item) }
    let(:campaign) { item.registration_campaign }

    context "when campaign is FCFS" do
      before do
        campaign.update(allocation_mode: "first_come_first_served")
        allow(item).to receive(:confirmed_registrations_count).and_return(5)
      end

      it "returns confirmed registrations count" do
        expect(helper.item_stats_count(item)).to eq(5)
      end
    end

    context "when campaign is preference based" do
      before { campaign.update(allocation_mode: "preference_based") }

      context "when status is open" do
        before do
          campaign.update(status: "open")
          allow(item).to receive(:first_choice_count).and_return(3)
        end

        it "returns first choice count" do
          expect(helper.item_stats_count(item)).to eq(3)
        end
      end

      context "when status is completed" do
        before do
          campaign.update(status: "completed")
          allow(item).to receive(:confirmed_registrations_count).and_return(7)
        end

        it "returns confirmed registrations count" do
          expect(helper.item_stats_count(item)).to eq(7)
        end
      end
    end
  end

  describe "#item_capacity_percentage" do
    let(:item) { build(:registration_item, capacity: 10) }

    it "returns 0 if capacity is zero" do
      item.capacity = 0
      expect(helper.item_capacity_percentage(item)).to eq(0)
    end

    it "returns correct percentage" do
      allow(item).to receive(:confirmed_registrations_count).and_return(5)
      expect(helper.item_capacity_percentage(item)).to eq(50)
    end

    it "clamps to 100" do
      allow(item).to receive(:confirmed_registrations_count).and_return(15)
      expect(helper.item_capacity_percentage(item)).to eq(100)
    end
  end

  describe "#item_capacity_progress_color" do
    let(:item) { build(:registration_item, capacity: 10) }

    it "returns success for low usage" do
      allow(item).to receive(:confirmed_registrations_count).and_return(5)
      expect(helper.item_capacity_progress_color(item)).to eq("success")
    end

    it "returns warning for high usage" do
      allow(item).to receive(:confirmed_registrations_count).and_return(8)
      expect(helper.item_capacity_progress_color(item)).to eq("warning")
    end

    it "returns danger for full usage" do
      allow(item).to receive(:confirmed_registrations_count).and_return(10)
      expect(helper.item_capacity_progress_color(item)).to eq("danger")
    end
  end

  describe "#show_item_capacity_progress?" do
    let(:campaign) { build(:registration_campaign, :first_come_first_served) }
    let(:item) { build(:registration_item, registration_campaign: campaign, capacity: 10) }

    it "returns true for FCFS with capacity" do
      expect(helper.show_item_capacity_progress?(item)).to be(true)
    end

    it "returns false for FCFS without capacity" do
      item.capacity = 0
      expect(helper.show_item_capacity_progress?(item)).to be(false)
    end

    it "returns false for preference based" do
      campaign.allocation_mode = :preference_based
      expect(helper.show_item_capacity_progress?(item)).to be(false)
    end
  end

  describe "#campaign_close_confirmation" do
    it "returns the correct confirmation message" do
      campaign = build(:registration_campaign, registration_deadline: 1.day.from_now)
      expect(helper.campaign_close_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.close_early"))

      campaign.registration_deadline = 1.day.ago
      expect(helper.campaign_close_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.close"))
    end
  end
end
