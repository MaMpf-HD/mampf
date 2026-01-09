require "rails_helper"

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

  describe "#sorted_preference_counts" do
    it "sorts ranks correctly with forced last" do
      stats = double(preference_counts: { 2 => 10, :forced => 5, 1 => 20 })
      sorted = helper.sorted_preference_counts(stats)
      expect(sorted).to eq([[1, 20], [2, 10], [:forced, 5]])
    end
  end

  describe "#rank_color" do
    it "returns correct colors for ranks" do
      expect(helper.rank_color(1)).to eq(:success)
      expect(helper.rank_color(2)).to eq(:primary)
      expect(helper.rank_color(3)).to eq(:secondary)
      expect(helper.rank_color(:forced)).to eq(:danger)
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

  describe "#campaign_open_confirmation" do
    let(:campaign) { build(:registration_campaign) }

    it "returns standard confirmation for regular campaign" do
      expect(helper.campaign_open_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.open"))
    end

    it "returns planning confirmation for planning campaign" do
      campaign.planning_only = true
      expect(helper.campaign_open_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.open_planning"))
    end

    it "appends warning for unlimited items" do
      create(:registration_item, registration_campaign: campaign, capacity: nil)
      expect(helper.campaign_open_confirmation(campaign))
        .to include(I18n.t("registration.campaign.warnings.unlimited_items"))
    end
  end

  describe "#planning_only_disabled_reason" do
    let(:lecture) { create(:lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture) }

    context "when campaign can be planning only" do
      it "returns nil" do
        expect(helper.planning_only_disabled_reason(campaign)).to be_nil
      end
    end

    context "when campaign cannot be planning only" do
      before do
        create(:registration_item, registration_campaign: campaign,
                                   registerable: create(:tutorial, lecture: lecture))
      end

      it "returns the translated reason" do
        expect(helper.planning_only_disabled_reason(campaign))
          .to eq(I18n.t("registration.campaign.planning_only_disabled"))
      end
    end
  end

  describe "#rank_label" do
    it "returns forced label for :forced" do
      expect(helper.rank_label(:forced)).to eq(I18n.t("registration.allocation.stats.forced"))
    end

    it "returns rank label for numbers" do
      expect(helper.rank_label(1)).to eq(I18n.t("registration.allocation.stats.rank_label",
                                                rank: 1))
    end
  end

  describe "#planning_only_checkbox_disabled?" do
    let(:campaign) { build(:registration_campaign) }

    it "returns true if campaign cannot be planning only" do
      allow(campaign).to receive(:can_be_planning_only?).and_return(false)
      expect(helper.planning_only_checkbox_disabled?(campaign)).to be(true)
    end

    it "returns true if campaign is not draft" do
      allow(campaign).to receive(:can_be_planning_only?).and_return(true)
      campaign.status = :open
      expect(helper.planning_only_checkbox_disabled?(campaign)).to be(true)
    end

    it "returns false if campaign can be planning only and is draft" do
      allow(campaign).to receive(:can_be_planning_only?).and_return(true)
      campaign.status = :draft
      expect(helper.planning_only_checkbox_disabled?(campaign)).to be(false)
    end
  end

  describe "#campaign_items_empty?" do
    let(:campaign) { create(:registration_campaign) }

    it "returns true when empty" do
      expect(helper.send(:campaign_items_empty?, campaign)).to be(true)
    end

    context "with items" do
      let(:campaign) { create(:registration_campaign, :with_items) }

      it "returns false" do
        expect(helper.send(:campaign_items_empty?, campaign)).to be(false)
      end

      it "returns false (loaded)" do
        campaign.registration_items.load
        expect(campaign.association(:registration_items)).to be_loaded
        expect(helper.send(:campaign_items_empty?, campaign)).to be(false)
      end
    end
  end
end
