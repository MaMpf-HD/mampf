require "rails_helper"

RSpec.describe(Rosters::MaintenanceService, type: :model) do
  subject { described_class.new }
  let(:user) { create(:user) }
  let(:tutorial) { create(:tutorial, capacity: 1) }
  let(:other_tutorial) { create(:tutorial, capacity: 5) }

  describe "#add_user!" do
    context "when roster has capacity" do
      it "adds the user to the roster" do
        expect do
          subject.add_user!(user, tutorial)
        end.to change { tutorial.members.count }.by(1)
      end
    end

    context "when roster is full" do
      before { create(:tutorial_membership, tutorial: tutorial) }

      it "raises CapacityExceededError" do
        expect do
          subject.add_user!(user, tutorial)
        end.to raise_error(Rosters::MaintenanceService::CapacityExceededError)
      end

      it "adds the user if force is true" do
        expect do
          subject.add_user!(user, tutorial, force: true)
        end.to change { tutorial.members.count }.by(1)
      end
    end

    context "when user is already in roster" do
      before { create(:tutorial_membership, tutorial: tutorial, user: user) }

      it "does nothing" do
        expect do
          subject.add_user!(user, tutorial)
        end.not_to(change { tutorial.members.count })
      end
    end

    context "when a registration exists" do
      let(:campaign) { create(:registration_campaign) }
      let(:item) do
        create(:registration_item, registration_campaign: campaign,
                                   registerable: tutorial)
      end
      let!(:registration) do
        create(:registration_user_registration, user: user, registration_item: item,
                                                registration_campaign: campaign)
      end

      it "updates the materialized_at timestamp" do
        expect do
          subject.add_user!(user, tutorial)
        end.to change { registration.reload.materialized_at }.from(nil)
      end
    end

    context "when user is already in another tutorial of the same lecture" do
      let(:lecture) { create(:lecture) }
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:other_tutorial) { create(:tutorial, lecture: lecture) }

      before do
        create(:tutorial_membership, tutorial: other_tutorial, user: user)
      end

      it "raises UserAlreadyInBundleError" do
        expect do
          subject.add_user!(user, tutorial)
        end.to raise_error(Rosters::UserAlreadyInBundleError)
      end
    end
  end

  describe "#remove_user!" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "removes the user from the roster" do
      expect do
        subject.remove_user!(user, tutorial)
      end.to change { tutorial.members.count }.by(-1)
    end
  end

  describe "#move_user!" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "moves the user from one roster to another" do
      expect do
        subject.move_user!(user, tutorial, other_tutorial)
      end.to change { tutorial.members.count }.by(-1)
                                              .and(change { other_tutorial.members.count }.by(1))
    end

    context "when target roster is full" do
      let(:full_tutorial) { create(:tutorial, capacity: 0) }

      it "raises CapacityExceededError and does not remove user from source" do
        expect do
          subject.move_user!(user, tutorial, full_tutorial)
        end.to raise_error(Rosters::MaintenanceService::CapacityExceededError)

        expect(tutorial.members).to include(user)
        expect(full_tutorial.members).not_to include(user)
      end
    end
  end
end
