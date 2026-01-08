require "rails_helper"

RSpec.describe(Rosters::Rosterable) do
  it "ensures all including models have a manual_roster_mode attribute" do
    # Eager load the application to ensure all models are loaded and discoverable
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.select do |model|
      model.included_modules.include?(described_class)
    end

    models.each do |model|
      expect(model.new)
        .to(respond_to(:manual_roster_mode), "#{model} must have a manual_roster_mode attribute")
    end
  end

  describe "#locked?" do
    let(:rosterable) { create(:tutorial, manual_roster_mode: true) }

    context "when in manual mode" do
      # manual_roster_mode: true
      it "returns false" do
        expect(rosterable.locked?).to(be(false))
      end
    end

    context "when in system mode" do
      before { rosterable.update(manual_roster_mode: false) }

      context "with no campaigns" do
        it "returns true" do
          expect(rosterable.locked?).to(be(true))
        end
      end

      context "with an open campaign" do
        before do
          campaign = create(:registration_campaign, status: :draft, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
          campaign.update(status: :open)
        end

        it "returns true" do
          expect(rosterable.locked?).to(be(true))
        end
      end

      context "with a completed planning campaign" do
        let(:rosterable) { create(:lecture, manual_roster_mode: false) }

        before do
          campaign = create(:registration_campaign, status: :completed, planning_only: true,
                                                    campaignable: rosterable)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "returns false" do
          expect(rosterable.locked?).to(be(false))
        end
      end

      context "with a completed non-planning campaign" do
        before do
          campaign = create(:registration_campaign, status: :completed, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "returns false" do
          expect(rosterable.locked?).to(be(false))
        end
      end
    end
  end

  describe "#can_enable_manual_mode?" do
    # Was can_disable_campaign_management?
    # System -> Manual
    let(:rosterable) { create(:tutorial, manual_roster_mode: false) }

    context "when campaign is running" do
      before do
        campaign = create(:registration_campaign, campaignable: rosterable.lecture, status: :draft,
                                                  planning_only: false)
        create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        campaign.update(status: :open)
      end

      it "returns false" do
        expect(rosterable.can_enable_manual_mode?).to(be(false))
      end
    end

    context "when no campaign is running" do
      it "returns true" do
        expect(rosterable.can_enable_manual_mode?).to(be(true))
      end
    end
  end

  describe "validations" do
    context "when creating a new record" do
      it "allows manual_roster_mode: true" do
        new_tutorial = build(:tutorial, manual_roster_mode: true)
        expect(new_tutorial).to be_valid
      end

      it "allows manual_roster_mode: false" do
        new_tutorial = build(:tutorial, manual_roster_mode: false)
        expect(new_tutorial).to be_valid
      end
    end

    # Switching Manual -> System (enabling managed_by_campaign)
    # Corresponds to manual_roster_mode: true -> false
    context "when disabling manual_roster_mode" do
      let(:rosterable) { create(:tutorial, manual_roster_mode: true) }

      context "when roster is empty" do
        it "is valid" do
          rosterable.manual_roster_mode = false
          expect(rosterable).to(be_valid)
        end
      end

      context "when roster is not empty" do
        before do
          rosterable.add_user_to_roster!(create(:user))
        end

        it "is invalid" do
          rosterable.manual_roster_mode = false
          expect(rosterable).not_to(be_valid)
          expect(rosterable.errors[:manual_roster_mode])
            .to(include(I18n.t("roster.errors.roster_not_empty")))
        end
      end
    end

    # Switching System -> Manual (disabling managed_by_campaign)
    # Corresponds to manual_roster_mode: false -> true
    context "when enabling manual_roster_mode" do
      let(:rosterable) { create(:tutorial, manual_roster_mode: false) }

      context "when campaign is running" do
        before do
          campaign = create(:registration_campaign, campaignable: rosterable.lecture,
                                                    status: :draft, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "is invalid" do
          rosterable.manual_roster_mode = true
          expect(rosterable).not_to(be_valid)
          expect(rosterable.errors[:manual_roster_mode])
            .to(include(I18n.t("roster.errors.campaign_associated")))
        end
      end

      context "when no campaign is running" do
        it "is valid" do
          rosterable.manual_roster_mode = true
          expect(rosterable).to(be_valid)
        end
      end
    end
  end

  describe "#materialize_allocation!" do
    let(:rosterable) { create(:tutorial) }
    let(:campaign) { create(:registration_campaign) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      # Initial state: user1 is in roster (via campaign), user2 is in roster (manual)
      rosterable.add_user_to_roster!(user1, campaign)
      rosterable.add_user_to_roster!(user2, nil)
    end

    it "adds new users from the list" do
      rosterable.materialize_allocation!(user_ids: [user1.id, user3.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).to include(user3.id)
    end

    it "removes users not in the list who were added by this campaign" do
      rosterable.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).not_to include(user1.id)
    end

    it "preserves manual entries" do
      rosterable.materialize_allocation!(user_ids: [user1.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).to include(user2.id)
    end

    it "preserves entries from other campaigns" do
      other_campaign = create(:registration_campaign)
      rosterable.add_user_to_roster!(user3, other_campaign)

      rosterable.materialize_allocation!(user_ids: [user1.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).to include(user3.id)
    end

    context "propagation to lecture roster" do
      let(:lecture) { rosterable.lecture }

      it "propagates tutorial allocations to the parent lecture" do
        rosterable.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
        expect(lecture.allocated_user_ids).to include(user3.id)
      end

      context "with a cohort" do
        let(:rosterable) { create(:cohort, context: create(:lecture)) }
        let(:lecture) { rosterable.lecture }

        it "does not propagate by default" do
          rosterable.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
          expect(lecture.allocated_user_ids).not_to include(user3.id)
        end

        it "propagates when propagate_to_lecture is enabled" do
          propagating = create(:cohort, context: lecture, propagate_to_lecture: true)
          expect(propagating.propagate_to_lecture?).to be(true)

          propagating.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
          expect(lecture.allocated_user_ids).to include(user3.id)
        end
      end
    end
  end

  describe "capacity checks" do
    let(:rosterable) { create(:tutorial) }

    before do
      allow(rosterable).to receive(:capacity).and_return(2)
    end

    describe "#over_capacity?" do
      it "returns false when under capacity" do
        expect(rosterable.over_capacity?).to be(false)
      end

      it "returns false when at capacity" do
        create_list(:tutorial_membership, 2, tutorial: rosterable)
        expect(rosterable.over_capacity?).to be(false)
      end

      it "returns true when over capacity" do
        create_list(:tutorial_membership, 3, tutorial: rosterable)
        expect(rosterable.over_capacity?).to be(true)
      end

      it "returns false if capacity is nil" do
        allow(rosterable).to receive(:capacity).and_return(nil)
        create_list(:tutorial_membership, 3, tutorial: rosterable)
        expect(rosterable.over_capacity?).to be(false)
      end
    end

    describe "#full?" do
      it "returns false when under capacity" do
        expect(rosterable.full?).to be(false)
      end

      it "returns true when at capacity" do
        create_list(:tutorial_membership, 2, tutorial: rosterable)
        expect(rosterable.full?).to be(true)
      end

      it "returns true when over capacity" do
        create_list(:tutorial_membership, 3, tutorial: rosterable)
        expect(rosterable.full?).to be(true)
      end
    end
  end

  describe "roster management" do
    let(:rosterable) { create(:tutorial) }
    let(:user) { create(:user) }

    describe "#add_user_to_roster!" do
      it "adds the user to the roster" do
        expect { rosterable.add_user_to_roster!(user) }
          .to change { rosterable.roster_entries.count }.by(1)
        expect(rosterable.allocated_user_ids).to include(user.id)
      end
    end

    describe "#remove_user_from_roster!" do
      before { rosterable.add_user_to_roster!(user) }

      it "removes the user from the roster" do
        expect { rosterable.remove_user_from_roster!(user) }
          .to change { rosterable.roster_entries.count }.by(-1)
        expect(rosterable.allocated_user_ids).not_to include(user.id)
      end
    end

    describe "#roster_empty?" do
      it "returns true when empty" do
        expect(rosterable.roster_empty?).to be(true)
      end

      it "returns false when not empty" do
        rosterable.add_user_to_roster!(user)
        expect(rosterable.roster_empty?).to be(false)
      end
    end
  end

  describe "#destructible?" do
    let(:rosterable) { create(:tutorial) }

    context "when not in a campaign and roster is empty" do
      it "returns true" do
        expect(rosterable.destructible?).to(be(true))
      end
    end

    context "when in a real campaign" do
      before do
        campaign = create(:registration_campaign, status: :draft, planning_only: false)
        create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        campaign.update(status: :open)
      end

      it "returns false" do
        expect(rosterable.destructible?).to(be(false))
      end
    end

    context "when roster is not empty" do
      before do
        rosterable.add_user_to_roster!(create(:user))
      end

      it "returns false" do
        expect(rosterable.destructible?).to(be(false))
      end
    end
  end

  describe "#enforce_rosterable_destruction_constraints" do
    let(:rosterable) { create(:tutorial) }

    context "when in a real campaign" do
      before do
        campaign = create(:registration_campaign, status: :draft, planning_only: false)
        create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        campaign.update(status: :open)
      end

      it "adds an error and aborts destruction" do
        rosterable.destroy
        expect(rosterable.errors[:base])
          .to(include(I18n.t("roster.errors.cannot_delete_in_campaign")))
        expect(rosterable).not_to(be_destroyed)
      end
    end

    context "when roster is not empty" do
      before do
        rosterable.add_user_to_roster!(create(:user))
      end

      it "adds an error and aborts destruction" do
        rosterable.destroy
        expect(rosterable.errors[:base])
          .to(include(I18n.t("roster.errors.cannot_delete_not_empty")))
        expect(rosterable).not_to(be_destroyed)
      end
    end

    context "when safe to destroy" do
      it "allows destruction" do
        rosterable.destroy
        expect(rosterable).to(be_destroyed)
      end
    end
  end
end
