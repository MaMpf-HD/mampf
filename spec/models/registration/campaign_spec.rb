require "rails_helper"

RSpec.describe(Registration::Campaign, type: :model) do
  describe "factory" do
    it "creates a valid default campaign" do
      campaign = FactoryBot.create(:registration_campaign)
      expect(campaign).to be_valid
      expect(campaign.allocation_mode).to eq("first_come_first_served")
      expect(campaign.status).to eq("draft")
      expect(campaign.registration_items).to be_empty
    end

    it "creates a valid first_come_first_served campaign" do
      campaign = FactoryBot.create(:registration_campaign, :first_come_first_served)
      expect(campaign).to be_valid
      expect(campaign.allocation_mode).to eq("first_come_first_served")
    end

    it "creates a valid preference_based campaign" do
      campaign = FactoryBot.create(:registration_campaign, :preference_based)
      expect(campaign).to be_valid
      expect(campaign.allocation_mode).to eq("preference_based")
    end

    it "creates a valid open campaign" do
      campaign = FactoryBot.create(:registration_campaign, :open)
      expect(campaign).to be_valid
      expect(campaign.status).to eq("open")
    end

    it "creates a valid closed campaign" do
      campaign = FactoryBot.create(:registration_campaign, :closed)
      expect(campaign).to be_valid
      expect(campaign.status).to eq("closed")
    end

    it "creates a valid processing campaign" do
      campaign = FactoryBot.create(:registration_campaign, :processing)
      expect(campaign).to be_valid
      expect(campaign.status).to eq("processing")
    end

    it "creates a valid completed campaign" do
      campaign = FactoryBot.create(:registration_campaign, :completed)
      expect(campaign).to be_valid
      expect(campaign.status).to eq("completed")
    end

    it "creates a valid planning_only campaign" do
      campaign = FactoryBot.create(:registration_campaign, :planning_only)
      expect(campaign).to be_valid
      expect(campaign.planning_only).to be(true)
    end

    it "creates campaign with items for regular lecture" do
      campaign = FactoryBot.create(:registration_campaign, :with_items)
      expect(campaign).to be_valid
      expect(campaign.registration_items.count).to eq(3)
      expect(campaign.registration_items.map(&:registerable_type).uniq).to eq(["Tutorial"])
      campaign.registration_items.each do |item|
        expect(item.registerable.lecture).to eq(campaign.campaignable)
      end
    end

    it "creates seminar campaign without items by default" do
      campaign = FactoryBot.create(:registration_campaign, :for_seminar)
      expect(campaign).to be_valid
      expect(campaign.campaignable.seminar?).to be(true)
      expect(campaign.registration_items).to be_empty
    end

    it "creates seminar campaign with talks when using :with_items" do
      campaign = FactoryBot.create(:registration_campaign, :for_seminar, :with_items)
      expect(campaign).to be_valid
      expect(campaign.campaignable.seminar?).to be(true)
      expect(campaign.registration_items.count).to eq(3)
      expect(campaign.registration_items.map(&:registerable_type).uniq).to eq(["Talk"])
      campaign.registration_items.each do |item|
        expect(item.registerable.lecture).to eq(campaign.campaignable)
      end
    end

    it "creates campaign for lecture enrollment" do
      campaign = FactoryBot.create(:registration_campaign, :for_lecture_enrollment)
      expect(campaign).to be_valid
      expect(campaign.registration_items.count).to eq(1)
      item = campaign.registration_items.first
      expect(item.registerable_type).to eq("Lecture")
      expect(item.registerable).to eq(campaign.campaignable)
    end

    it "creates campaign with policies" do
      campaign = FactoryBot.create(:registration_campaign, :with_policies)
      expect(campaign).to be_valid
      expect(campaign.registration_policies.count).to eq(1)
      expect(campaign.registration_policies.first.kind).to eq("institutional_email")
    end
  end
end
