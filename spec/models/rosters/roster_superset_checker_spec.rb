require "rails_helper"

RSpec.describe(Rosters::RosterSupersetChecker) do
  subject { described_class.new }

  let(:lecture) { create(:lecture) }

  describe "#check_all_lectures!" do
    context "when superset invariant holds" do
      it "logs no violations for users in both tutorial and lecture" do
        tutorial = create(:tutorial, lecture: lecture)
        user = create(:user)

        create(:tutorial_membership, tutorial: tutorial, user: user)
        create(:lecture_membership, lecture: lecture, user: user)

        expect(Rails.logger).not_to receive(:error)
          .with(/RosterSupersetViolation/)

        subject.check_all_lectures!
      end

      it "logs no violations for users in both propagating cohort and lecture" do
        cohort = create(:cohort, context: lecture, propagate_to_lecture: true)
        user = create(:user)

        create(:cohort_membership, cohort: cohort, user: user)
        create(:lecture_membership, lecture: lecture, user: user)

        expect(Rails.logger).not_to receive(:error)
          .with(/RosterSupersetViolation/)

        subject.check_all_lectures!
      end
    end

    context "when user missing from lecture roster" do
      it "logs violation for user in tutorial but not lecture" do
        tutorial = create(:tutorial, lecture: lecture)
        user = create(:user)

        create(:tutorial_membership, tutorial: tutorial, user: user)

        expect { subject.check_all_lectures! }
          .to raise_error(Rosters::RosterSupersetChecker::RosterSupersetViolationError,
                          /Found 1 roster superset violations/)
      end

      it "includes user details in violation log" do
        tutorial = create(:tutorial, lecture: lecture)
        user = create(:user, email: "test@example.com")

        create(:tutorial_membership, tutorial: tutorial, user: user)

        logs = []
        original_error = Rails.logger.method(:error)
        allow(Rails.logger).to receive(:error) do |*args|
          logs << args.first
          original_error.call(*args)
        end

        expect { subject.check_all_lectures! }
          .to raise_error(Rosters::RosterSupersetChecker::RosterSupersetViolationError)

        combined_log = logs.join(" ")
        expect(combined_log).to include(user.id.to_s)
        expect(combined_log).to include("test@example.com")
        expect(combined_log).to include("Tutorial: #{tutorial.title}")
      end

      it "logs violation for user in propagating cohort but not lecture" do
        cohort = create(:cohort, context: lecture, propagate_to_lecture: true)
        user = create(:user)

        create(:cohort_membership, cohort: cohort, user: user)

        expect { subject.check_all_lectures! }
          .to raise_error(Rosters::RosterSupersetChecker::RosterSupersetViolationError)
      end

      it "reports multiple violations in single lecture" do
        tutorial = create(:tutorial, lecture: lecture)
        user1 = create(:user)
        user2 = create(:user)

        create(:tutorial_membership, tutorial: tutorial, user: user1)
        create(:tutorial_membership, tutorial: tutorial, user: user2)

        expect { subject.check_all_lectures! }
          .to raise_error(Rosters::RosterSupersetChecker::RosterSupersetViolationError,
                          /Found 2 roster superset violations/)
      end
    end

    context "with non-propagating cohorts" do
      it "ignores users in non-propagating cohorts" do
        cohort = create(:cohort, context: lecture, propagate_to_lecture: false)
        user = create(:user)

        create(:cohort_membership, cohort: cohort, user: user)

        expect(Rails.logger).not_to receive(:error)
          .with(/RosterSupersetViolation/)

        subject.check_all_lectures!
      end

      it "correctly identifies planning cohorts as non-propagating" do
        cohort = create(:cohort, context: lecture, purpose: :planning,
                                 propagate_to_lecture: false)
        user = create(:user)

        create(:cohort_membership, cohort: cohort, user: user)

        expect(Rails.logger).not_to receive(:error)

        subject.check_all_lectures!
      end
    end

    context "with user in multiple groups" do
      it "lists all groups where user is found" do
        tutorial = create(:tutorial, lecture: lecture)
        cohort = create(:cohort, context: lecture, propagate_to_lecture: true)
        user = create(:user)

        create(:tutorial_membership, tutorial: tutorial, user: user)
        create(:cohort_membership, cohort: cohort, user: user)

        logs = []
        original_error = Rails.logger.method(:error)
        allow(Rails.logger).to receive(:error) do |*args|
          logs << args.first
          original_error.call(*args)
        end

        expect { subject.check_all_lectures! }
          .to raise_error(Rosters::RosterSupersetChecker::RosterSupersetViolationError)

        combined_log = logs.join(" ")
        expect(combined_log).to include("Tutorial: #{tutorial.title}")
        expect(combined_log).to include("Cohort: #{cohort.title}")
      end
    end

    context "with deleted users" do
      it "handles deleted users gracefully" do
        tutorial = create(:tutorial, lecture: lecture)
        user = create(:user)

        create(:tutorial_membership, tutorial: tutorial, user: user)

        allow(User).to receive(:find_by).with(id: user.id).and_return(nil)

        logs = []
        original_error = Rails.logger.method(:error)
        allow(Rails.logger).to receive(:error) do |*args|
          logs << args.first
          original_error.call(*args)
        end

        expect { subject.check_all_lectures! }
          .to raise_error(Rosters::RosterSupersetChecker::RosterSupersetViolationError)

        combined_log = logs.join(" ")
        expect(combined_log).to include(user.id.to_s)
        expect(combined_log).to include("Unknown")
      end
    end

    context "with multiple lectures" do
      it "checks all lectures" do
        create(:lecture)
        create(:lecture)

        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info)
          .with(/checked 2 lectures/)

        subject.check_all_lectures!
      end
    end

    context "when no violations exist" do
      it "logs completion with zero violations" do
        tutorial = create(:tutorial, lecture: lecture)
        user = create(:user)

        create(:tutorial_membership, tutorial: tutorial, user: user)
        create(:lecture_membership, lecture: lecture, user: user)

        expect(Rails.logger).to receive(:info).with(/Starting nightly check/)
        expect(Rails.logger).to receive(:info).with(/found 0 violations/)

        subject.check_all_lectures!
      end
    end
  end
end
