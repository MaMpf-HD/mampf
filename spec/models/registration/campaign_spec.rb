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
      expect(campaign.registration_items).not_to be_empty
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

  describe "validations" do
    it "validates registration_deadline is in the future if open" do
      campaign = create(:registration_campaign, :open)
      campaign.registration_deadline = 1.day.ago
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

    describe "#description" do
      it "validates maximum length of 100" do
        campaign = build(:registration_campaign, description: "a" * 101)
        expect(campaign).not_to be_valid
        expect(campaign.errors[:description]).to include(I18n.t("errors.messages.too_long",
                                                                count: 100))
      end

      it "allows length of 100" do
        campaign = build(:registration_campaign, description: "a" * 100)
        expect(campaign).to be_valid
      end
    end

    describe "#planning_only" do
      let(:lecture) { create(:lecture) }
      let(:campaign) { create(:registration_campaign, campaignable: lecture, planning_only: true) }

      context "when campaign has no items" do
        it "is valid" do
          expect(campaign).to be_valid
        end
      end

      context "when campaign has lecture item" do
        before do
          create(:registration_item, registration_campaign: campaign, registerable: lecture)
        end

        it "is valid" do
          expect(campaign).to be_valid
        end
      end

      context "when campaign has tutorial items" do
        let(:campaign) do
          create(:registration_campaign, campaignable: lecture, planning_only: false)
        end

        before do
          create(:registration_item, registration_campaign: campaign,
                                     registerable: create(:tutorial, lecture: lecture))
          campaign.planning_only = true
        end

        it "is invalid" do
          expect(campaign).not_to be_valid
          expect(campaign.errors[:planning_only])
            .to include(I18n.t("activerecord.errors.models.registration/campaign.attributes" \
                               ".planning_only.incompatible_items"))
        end
      end
    end

    describe "#ensure_editable" do
      let(:campaign) { create(:registration_campaign, :completed) }

      it "prevents updates if campaign is completed" do
        campaign.description = "New description"
        expect(campaign).not_to be_valid
        expect(campaign.errors.added?(:base, :already_finalized)).to be(true)
      end

      it "allows updates if status is changing (re-opening)" do
        campaign.status = :open
        campaign.registration_deadline = 1.day.from_now
        expect(campaign).to be_valid
      end

      it "allows updates if status is changing (finalizing)" do
        campaign = create(:registration_campaign, :processing)
        campaign.status = :completed
        expect(campaign).to be_valid
      end
    end

    describe "#validate_real_campaign_uniqueness" do
      let(:lecture) { create(:lecture) }

      context "when a standard campaign already exists" do
        let!(:existing_campaign) do
          create(:registration_campaign, campaignable: lecture, planning_only: false)
        end

        it "allows creating another standard campaign (uniqueness is enforced by items)" do
          new_campaign = build(:registration_campaign, campaignable: lecture, planning_only: false)
          expect(new_campaign).to be_valid
        end
      end

      context "when a planning_only campaign already exists" do
        let!(:existing_campaign) do
          create(:registration_campaign, campaignable: lecture, planning_only: true)
        end

        it "allows creating a standard campaign" do
          new_campaign = build(:registration_campaign, campaignable: lecture, planning_only: false)
          expect(new_campaign).to be_valid
        end

        it "allows creating another planning_only campaign" do
          new_campaign = build(:registration_campaign, campaignable: lecture, planning_only: true)
          expect(new_campaign).to be_valid
        end
      end
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

  describe "registration counts" do
    context "with preference based campaign" do
      let(:campaign) { create(:registration_campaign, :with_items, :preference_based) }
      let(:item1) { campaign.registration_items.first }
      let(:item2) { campaign.registration_items.second }
      let(:user) { create(:user) }

      it "counts confirmed users correctly" do
        create(:registration_user_registration, registration_campaign: campaign,
                                                registration_item: item1,
                                                status: :confirmed,
                                                preference_rank: 1)

        expect(campaign.confirmed_count).to eq(1)
        expect(campaign.pending_count).to eq(0)
        expect(campaign.rejected_count).to eq(0)
        expect(campaign.total_registrations_count).to eq(1)
      end

      it "counts pending users correctly" do
        create(:registration_user_registration, registration_campaign: campaign,
                                                registration_item: item1,
                                                status: :pending,
                                                preference_rank: 1)

        expect(campaign.confirmed_count).to eq(0)
        expect(campaign.pending_count).to eq(1)
        expect(campaign.rejected_count).to eq(0)
        expect(campaign.total_registrations_count).to eq(1)
      end

      it "counts rejected users correctly" do
        create(:registration_user_registration, registration_campaign: campaign,
                                                registration_item: item1,
                                                status: :rejected,
                                                preference_rank: 1)

        expect(campaign.confirmed_count).to eq(0)
        expect(campaign.pending_count).to eq(0)
        expect(campaign.rejected_count).to eq(1)
        expect(campaign.total_registrations_count).to eq(1)
      end

      it "prioritizes confirmed status over pending and rejected" do
        # Confirmed on item 1
        create(:registration_user_registration, user: user,
                                                registration_campaign: campaign,
                                                registration_item: item1,
                                                status: :confirmed,
                                                preference_rank: 1)
        # Pending on item 2
        create(:registration_user_registration, user: user,
                                                registration_campaign: campaign,
                                                registration_item: item2,
                                                status: :pending,
                                                preference_rank: 2)

        expect(campaign.confirmed_count).to eq(1)
        expect(campaign.pending_count).to eq(0)
        expect(campaign.rejected_count).to eq(0)
        expect(campaign.total_registrations_count).to eq(1)
      end

      it "prioritizes pending status over rejected" do
        # Pending on item 1
        create(:registration_user_registration, user: user,
                                                registration_campaign: campaign,
                                                registration_item: item1,
                                                status: :pending,
                                                preference_rank: 1)
        # Rejected on item 2
        create(:registration_user_registration, user: user,
                                                registration_campaign: campaign,
                                                registration_item: item2,
                                                status: :rejected,
                                                preference_rank: 2)

        expect(campaign.confirmed_count).to eq(0)
        expect(campaign.pending_count).to eq(1)
        expect(campaign.rejected_count).to eq(0)
        expect(campaign.total_registrations_count).to eq(1)
      end

      it "counts distinct users only" do
        # Two pending registrations for same user
        create(:registration_user_registration, user: user,
                                                registration_campaign: campaign,
                                                registration_item: item1,
                                                status: :pending,
                                                preference_rank: 1)
        create(:registration_user_registration, user: user,
                                                registration_campaign: campaign,
                                                registration_item: item2,
                                                status: :pending,
                                                preference_rank: 2)

        expect(campaign.pending_count).to eq(1)
        expect(campaign.total_registrations_count).to eq(1)
      end
    end

    context "with FCFS campaign" do
      let(:campaign) { create(:registration_campaign, :with_items, :first_come_first_served) }
      let(:item1) { campaign.registration_items.first }

      it "counts confirmed users correctly" do
        create(:registration_user_registration, registration_campaign: campaign,
                                                registration_item: item1, status: :confirmed)

        expect(campaign.confirmed_count).to eq(1)
        expect(campaign.pending_count).to eq(0)
        expect(campaign.rejected_count).to eq(0)
        expect(campaign.total_registrations_count).to eq(1)
      end
    end
  end

  describe "#finalize!" do
    let(:campaign) { create(:registration_campaign, :with_items, status: :processing) }

    it "delegates to AllocationMaterializer and updates status" do
      expect_any_instance_of(Registration::AllocationMaterializer).to receive(:materialize!)

      expect do
        campaign.finalize!
      end.to change(campaign, :status).from("processing").to("completed")
    end

    it "updates pending registrations to rejected" do
      create(:registration_user_registration, registration_campaign: campaign, status: :pending)
      create(:registration_user_registration, registration_campaign: campaign, status: :confirmed)

      campaign.finalize!

      expect(campaign.user_registrations.pending).to be_empty
      expect(campaign.user_registrations.rejected.count).to eq(1)
      expect(campaign.user_registrations.confirmed.count).to eq(1)
    end

    context "when campaign is planning_only" do
      let(:lecture) { create(:lecture) }
      let(:campaign) do
        create(:registration_campaign, campaignable: lecture, planning_only: true,
                                       status: :processing)
      end
      let!(:item) do
        create(:registration_item, registration_campaign: campaign, registerable: lecture)
      end

      it "updates status to completed" do
        expect do
          campaign.finalize!
        end.to change(campaign, :status).from("processing").to("completed")
      end

      it "does not call AllocationMaterializer" do
        expect_any_instance_of(Registration::AllocationMaterializer).not_to receive(:materialize!)
        campaign.finalize!
      end

      it "does not reject pending registrations" do
        create(:registration_user_registration, registration_campaign: campaign,
                                                registration_item: item, status: :pending)

        campaign.finalize!

        expect(campaign.user_registrations.pending.count).to eq(1)
        expect(campaign.user_registrations.rejected.count).to eq(0)
      end
    end

    context "concurrency protection" do
      it "executes within a database lock" do
        expect(campaign).to receive(:with_lock).and_yield
        campaign.finalize!
      end

      it "aborts if campaign becomes completed while waiting for the lock" do
        # 1. Simulate acquiring the lock
        allow(campaign).to receive(:with_lock).and_yield

        # 2. Simulate that another process finished the job while we were waiting
        #    (The record is reloaded inside with_lock, so it sees the new status)
        allow(campaign).to receive(:completed?).and_return(true)

        # 3. Expect that we do NOT run the materialization logic again
        expect_any_instance_of(Registration::AllocationMaterializer).not_to receive(:materialize!)

        campaign.finalize!
      end
    end
  end

  describe "#user_registrations_grouped_by_user" do
    let(:campaign) { create(:registration_campaign, :with_items) }
    let(:user1) { create(:confirmed_user, name: "Alice") }
    let(:user2) { create(:confirmed_user, name: "Bob") }
    let(:user3) { create(:confirmed_user, name: "Charlie") }

    before do
      create(:registration_user_registration, registration_campaign: campaign, user: user2)
      create(:registration_user_registration, registration_campaign: campaign, user: user3)
      create(:registration_user_registration, registration_campaign: campaign, user: user1)
    end

    it "returns registrations grouped by user and ordered by user name" do
      grouped = campaign.user_registrations_grouped_by_user
      expect(grouped.keys.map(&:name)).to eq(["Alice", "Bob", "Charlie"])
      expect(grouped[user1].count).to eq(1)
      expect(grouped[user2].count).to eq(1)
      expect(grouped[user3].count).to eq(1)
    end
  end
end
