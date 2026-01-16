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

    it "creates campaign with policies" do
      campaign = FactoryBot.create(:registration_campaign, :with_policies)
      expect(campaign).to be_valid
      expect(campaign.registration_policies.count).to eq(1)
      expect(campaign.registration_policies.first.kind).to eq("institutional_email")
    end
  end

  describe "validations" do
    it "validates registration_deadline is in the future if open" do
      campaign = build(:registration_campaign, :open, registration_deadline: 1.day.ago)
      expect(campaign).not_to be_valid
      expect(campaign.errors.added?(:registration_deadline, :must_be_in_future)).to be(true)
    end

    it "validates prerequisites are not draft if open" do
      prereq = create(:registration_campaign, :draft)
      campaign = create(:registration_campaign, :draft)
      create(:registration_policy, :prerequisite_campaign,
             registration_campaign: campaign,
             config: { "prerequisite_campaign_id" => prereq.id })

      campaign.status = :open
      expect(campaign).not_to be_valid
      expect(campaign.errors.added?(:base, :prerequisite_is_draft,
                                    description: prereq.description)).to be(true)
    end
  end

  describe "deletion protection" do
    it "prevents deletion if not draft" do
      campaign = create(:registration_campaign, :open)
      expect { campaign.destroy }.not_to change(Registration::Campaign, :count)
      expect(campaign.errors.added?(:base, :cannot_delete_active_campaign)).to be(true)
    end

    it "prevents deletion if referenced as prerequisite" do
      prereq = create(:registration_campaign, :draft)
      dependent = create(:registration_campaign, :draft)
      create(:registration_policy, :prerequisite_campaign,
             registration_campaign: dependent,
             config: { "prerequisite_campaign_id" => prereq.id })

      expect { prereq.destroy }.not_to change(Registration::Campaign, :count)
      expect(prereq.errors.added?(:base, :referenced_as_prerequisite,
                                  descriptions: dependent.description)).to be(true)
    end
  end

  describe "freezing" do
    let(:campaign) { create(:registration_campaign, :open) }

    it "prevents changing allocation_mode if not draft" do
      campaign.allocation_mode = :preference_based
      expect(campaign).not_to be_valid
      expect(campaign.errors.added?(:allocation_mode, :frozen)).to be(true)
    end

    it "prevents reverting to draft from open" do
      campaign.status = :draft
      expect(campaign).not_to be_valid
      expect(campaign.errors.added?(:status, :cannot_revert_to_draft)).to be(true)
    end

    it "allows changing allocation_mode if draft" do
      draft_campaign = create(:registration_campaign, :draft)
      draft_campaign.allocation_mode = :preference_based
      expect(draft_campaign).to be_valid
    end
  end

  describe "#user_registration_confirmed?" do
    let(:campaign) { FactoryBot.create(:registration_campaign) }
    let(:user) { FactoryBot.create(:user) }

    it "returns false when user has no confirmed registration" do
      FactoryBot.create(
        :registration_user_registration,
        registration_campaign: campaign,
        user: user,
        status: :pending
      )

      expect(campaign.user_registration_confirmed?(user)).to be(false)
    end

    it "returns true when user has a confirmed registration" do
      FactoryBot.create(
        :registration_user_registration,
        registration_campaign: campaign,
        user: user,
        status: :confirmed
      )

      expect(campaign.user_registration_confirmed?(user)).to be(true)
    end
  end

  # This example only verifies delegation to PolicyEngine; both methods
  # evaluate_policies_for and policies_satisfied? are only thin wrappers.
  # Engine behavior is already tested in the policy_engine spec.
  describe "policy engine delegation" do
    let(:campaign) { FactoryBot.create(:registration_campaign) }
    let(:user) { FactoryBot.create(:user) }

    it "delegates evaluate_policies_for to PolicyEngine and returns its result" do
      engine = instance_double(Registration::PolicyEngine)
      result = Registration::PolicyEngine::Result.new(
        pass: true,
        failed_policy: nil,
        trace: []
      )

      allow(Registration::PolicyEngine).to receive(:new)
        .with(campaign)
        .and_return(engine)

      allow(engine).to receive(:eligible?)
        .with(user, phase: :registration)
        .and_return(result)

      returned = campaign.evaluate_policies_for(user, phase: :registration)

      expect(returned).to eq(result)
      expect(campaign.policies_satisfied?(user, phase: :registration)).to be(true)
    end
  end

  describe "#locale_with_inheritance" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:campaign) { FactoryBot.create(:registration_campaign, campaignable: lecture) }

    it "returns the locale of the campaignable" do
      allow(lecture).to receive(:locale_with_inheritance).and_return("de")
      expect(campaign.locale_with_inheritance).to eq("de")
    end

    it "falls back to locale if locale_with_inheritance is missing" do
      allow(lecture).to receive(:locale_with_inheritance).and_return(nil)
      allow(lecture).to receive(:locale).and_return("en")
      expect(campaign.locale_with_inheritance).to eq("en")
    end
  end
end
