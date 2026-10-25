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
      let(:campaign) { create(:registration_campaign, campaignable: tutorial.lecture) }
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

      # A list without enrollment would otherwise keep them in the lecture's
      # audience.
      it "removes the user from every group of the lecture, with enrollment or without" do
        expect do
          subject.remove_user!(user, lecture)
        end.to change { tutorial.members.count }.by(-1)
                                                .and(change {
                                                       propagating_cohort.members.count
                                                     }.by(-1))
                                                .and(change {
                                                       isolated_cohort.members.count
                                                     }.by(-1))
      end

      it "takes the bookmark along with the seat" do
        expect(user.reload.lectures).to include(lecture)

        subject.remove_user!(user, lecture)

        expect(user.reload.lectures).not_to include(lecture)
      end

      # A finalization would otherwise put them back into a group or onto an
      # exam list.
      it "withdraws the user's registrations in the lecture's running campaigns" do
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        registration = create(:registration_user_registration, :pending,
                              user: user, registration_campaign: campaign)

        subject.remove_user!(user, lecture)

        expect { registration.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "withdraws nothing for someone not on the lecture roster" do
        stranger = create(:confirmed_user)
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        registration = create(:registration_user_registration, :pending,
                              user: stranger, registration_campaign: campaign)

        expect(subject.remove_user!(stranger, lecture)).to be_falsey
        expect(registration.reload).to be_persisted
      end

      it "takes the user off the lecture's exam lists" do
        exam = create(:exam, :without_campaign, lecture: lecture)
        exam.add_user_to_roster!(user)

        subject.remove_user!(user, lecture)

        expect(exam.reload.users).not_to include(user)
      end

      it "refuses while an exam of the lecture holds a grade for the user" do
        exam = create(:exam, :without_campaign, lecture: lecture)
        exam.add_user_to_roster!(user)
        exam.ensure_assessment!(requires_points: false)
        Assessment::Participation.create!(assessment: exam.assessment, user: user,
                                          grade_numeric: 2.0, status: :reviewed)

        expect { subject.remove_user!(user, lecture) }
          .to raise_error(described_class::GradingDataPresentError)
        expect(lecture.reload.members).to include(user)
        expect(exam.reload.users).to include(user)
      end
    end
  end

  describe "enrollment following the places" do
    let(:lecture) { create(:lecture) }
    let(:mo) { create(:tutorial, lecture: lecture) }
    let(:list) { create(:cohort, context: lecture, propagate_to_lecture: false) }
    let(:staff) { create(:confirmed_user) }

    before { subject.add_user!(user, mo, force: true) }

    it "takes the user off the lecture with their last place, lists too" do
      subject.add_user!(user, list, force: true)

      expect(subject.remove_user!(user, mo, by: staff)).to eq(lecture)

      expect(lecture.reload.members).not_to include(user)
      expect(lecture.excluded_lecture_memberships.find_by(user: user).excluded_by).to eq(staff)
      expect(list.reload.members).not_to include(user)
    end

    # Whoever sits the exam stays a member through its list.
    it "keeps the lecture while the user is on an exam list" do
      create(:exam, :without_campaign, lecture: lecture).add_user_to_roster!(user)

      expect(subject.remove_user!(user, mo)).to eq(mo)
      expect(lecture.reload.members).to include(user)
    end

    # A finalization would otherwise place them again.
    it "withdraws the registrations in the lecture with the last place" do
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      registration = create(:registration_user_registration, :pending,
                            user: user, registration_campaign: campaign)

      subject.remove_user!(user, mo)

      expect { registration.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "keeps the registrations while another place remains" do
      subject.add_user!(user, create(:cohort, :enrollment, context: lecture), force: true)
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      registration = create(:registration_user_registration, :pending,
                            user: user, registration_campaign: campaign)

      subject.remove_user!(user, mo)

      expect(registration.reload).to be_persisted
    end

    it "locks the campaign, the group and then the lecture when the last place goes" do
      create(:registration_user_registration, :pending,
             user: user,
             registration_campaign: create(:registration_campaign, :open, campaignable: lecture))
      tables = []
      record = lambda do |*, payload|
        tables << payload[:sql][/FROM "(\w+)"/, 1] if payload[:sql].include?("FOR UPDATE")
      end
      ActiveSupport::Notifications.subscribed(record, "sql.active_record") do
        subject.remove_user!(user, mo)
      end

      expect(tables.index("registration_campaigns")).to be < tables.index("tutorials")
      expect(tables.index("tutorials")).to be < tables.index("lectures")
    end

    # A removal of the last place decides under the lecture's lock; a place
    # joined meanwhile has to wait for it, or it would be missed.
    it "locks the lecture after a group with enrollment that it adds to" do
      cohort = create(:cohort, :enrollment, context: lecture)
      tables = []
      record = lambda do |*, payload|
        tables << payload[:sql][/FROM "(\w+)"/, 1] if payload[:sql].include?("FOR UPDATE")
      end
      ActiveSupport::Notifications.subscribed(record, "sql.active_record") do
        subject.add_user!(user, cohort, force: true)
      end

      expect(tables.index("cohorts")).to be < tables.index("lectures")
    end

    it "keeps the lecture while another place remains" do
      subject.add_user!(user, create(:cohort, :enrollment, context: lecture), force: true)

      expect(subject.remove_user!(user, mo)).to eq(mo)
      expect(lecture.reload.members).to include(user)
    end

    # A list without enrollment is no place to stay enrolled through.
    it "does not count a list as a place" do
      subject.add_user!(user, list, force: true)

      subject.remove_user!(user, mo)

      expect(lecture.reload.members).not_to include(user)
    end

    it "lets the user leave a list without touching the lecture" do
      subject.add_user!(user, list, force: true)

      subject.remove_user!(user, list)

      expect(lecture.reload.members).to include(user)
    end

    it "refuses moving the last place onto a list" do
      expect { subject.move_user!(user, mo, list) }
        .to raise_error(described_class::MoveLeavesLectureError)
      expect(mo.reload.members).to include(user)
      expect(list.reload.members).not_to include(user)
    end

    describe "exam lists" do
      let(:exam) { create(:exam, :without_campaign, lecture: lecture) }
      let(:stranger) { create(:confirmed_user) }

      it "take the lecture's members" do
        expect(subject.add_user!(user, exam)).to be_present
      end

      # An exam list is a place: whoever sits only the exam is a member.
      it "enroll someone not yet in the lecture" do
        subject.add_user!(stranger, exam)

        expect(lecture.reload.members).to include(stranger)
      end

      it "take someone off the lecture with it when it was their last place" do
        subject.add_user!(stranger, exam)

        expect(subject.remove_user!(stranger, exam)).to eq(lecture)
        expect(lecture.reload.members).not_to include(stranger)
      end

      it "lock the lecture after the exam" do
        tables = []
        record = lambda do |*, payload|
          tables << payload[:sql][/FROM "(\w+)"/, 1] if payload[:sql].include?("FOR UPDATE")
        end
        ActiveSupport::Notifications.subscribed(record, "sql.active_record") do
          subject.add_user!(user, exam)
        end

        expect(tables.index("exams")).to be < tables.index("lectures")
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

      # Leaving the lecture on the way would take the lists along.
      context "when the source is the lecture and the target clashes with a group" do
        let(:tutorial_of_lecture) { create(:tutorial, lecture: lecture) }
        let(:other_tutorial_of_lecture) { create(:tutorial, lecture: lecture) }
        let(:list) { create(:cohort, context: lecture, propagate_to_lecture: false) }

        before do
          subject.add_user!(user, tutorial_of_lecture, force: true)
          subject.add_user!(user, list, force: true)
        end

        it "moves out of that group and keeps the enrollment and the lists" do
          expect(subject.move_user!(user, lecture, other_tutorial_of_lecture, force: true))
            .to be(true)

          expect(other_tutorial_of_lecture.members).to include(user)
          expect(tutorial_of_lecture.members).not_to include(user)
          expect(list.members).to include(user)
          expect(lecture.members).to include(user)
        end
      end
    end
  end
end
