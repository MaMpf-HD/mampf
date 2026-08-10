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

    context "when propagating to lecture" do
      let(:lecture) { create(:lecture) }
      let(:tutorial) { create(:tutorial, lecture: lecture) }

      it "adds the user to the lecture roster" do
        expect do
          subject.add_user!(user, tutorial)
        end.to change { lecture.members.count }.by(1)
      end

      it "checks idempotency" do
        subject.add_user!(user, tutorial)
        expect do
          subject.add_user!(user, tutorial)
        end.not_to(change { lecture.members.count })
      end
    end

    context "when the rosterable is the lecture itself" do
      let(:lecture) { create(:lecture) }

      it "creates a roster entry" do
        expect do
          subject.add_user!(user, lecture, force: true)
        end.to change { lecture.roster_entries.count }.by(1)
      end

      it "grants no access to the lecture" do
        expect do
          subject.add_user!(user, lecture, force: true)
        end.not_to(change { lecture.users.reload.count })
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

    context "when cascading from lecture" do
      let(:lecture) { create(:lecture) }
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:propagating_cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }
      let(:isolated_cohort) { create(:cohort, context: lecture, propagate_to_lecture: false) }

      before do
        # User is already in tutorial via outer before block
        tutorial.send(:propagate_to_lecture!, [user.id])
        # Manually add to cohorts
        create(:cohort_membership, cohort: propagating_cohort, user: user)
        create(:cohort_membership, cohort: isolated_cohort, user: user)
      end

      it "removes the user from propagating subgroups but keeps them in isolated ones" do
        expect do
          subject.remove_user!(user, lecture)
        end.to change { tutorial.members.count }.by(-1)
                                                .and(change {
                                                       propagating_cohort.members.count
                                                     }.by(-1))
                                                .and(change { isolated_cohort.members.count }.by(0))
      end
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

    it "locks source and target in deterministic order" do
      lock_order = []

      allow(subject).to receive(:remove_user_without_lock!)
      allow(subject).to receive(:add_user_without_lock!)

      allow(tutorial).to receive(:with_lock) do |_args, &block|
        lock_order << [tutorial.class.name, tutorial.id]
        block.call
      end
      allow(other_tutorial).to receive(:with_lock) do |_args, &block|
        lock_order << [other_tutorial.class.name, other_tutorial.id]
        block.call
      end

      subject.move_user!(user, other_tutorial, tutorial)

      expect(lock_order).to eq([["Tutorial", tutorial.id],
                                ["Tutorial", other_tutorial.id]])
    end

    describe "moves that would change nothing" do
      let(:lecture) { create(:lecture) }
      let(:cohort_a) { create(:cohort, context: lecture) }
      let(:cohort_b) { create(:cohort, context: lecture) }

      shared_examples "a move without effect" do
        it "leaves both rosters untouched" do
          expect do
            subject.move_user!(user, source, target, force: true)
          end.not_to(change do
            [source.roster_entries.reload.count, target.roster_entries.reload.count]
          end)
        end

        it "sends no notification and reports failure" do
          expect do
            expect(subject.move_user!(user, source, target, force: true)).to be(false)
          end.not_to have_enqueued_mail(RosterNotificationMailer, :moved_between_groups_email)
        end
      end

      context "when the user is already in the target" do
        let(:source) { cohort_a }
        let(:target) { cohort_b }

        before do
          subject.add_user!(user, cohort_a, force: true)
          subject.add_user!(user, cohort_b, force: true)
        end

        it_behaves_like "a move without effect"
      end

      context "when the user is not in the source" do
        let(:source) { cohort_a }
        let(:target) { cohort_b }

        before { subject.add_user!(user, cohort_b, force: true) }

        it_behaves_like "a move without effect"
      end

      context "when source and target are the same" do
        let(:source) { cohort_a }
        let(:target) { cohort_a }

        before { subject.add_user!(user, cohort_a, force: true) }

        it_behaves_like "a move without effect"
      end

      context "when the source is the lecture itself" do
        let(:source) { lecture }
        let(:target) { cohort_b }
        let(:tutorial_of_lecture) { create(:tutorial, lecture: lecture) }

        before do
          subject.add_user!(user, tutorial_of_lecture, force: true)
          subject.add_user!(user, cohort_b, force: true)
        end

        it_behaves_like "a move without effect"

        it "keeps the user in the subgroups of the lecture" do
          expect do
            subject.move_user!(user, lecture, cohort_b, force: true)
          end.not_to(change { tutorial_of_lecture.roster_entries.reload.count })
        end
      end
    end
  end
end
