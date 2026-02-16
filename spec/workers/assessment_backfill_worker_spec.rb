require "rails_helper"

RSpec.describe(AssessmentBackfillWorker) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:user1) { create(:confirmed_user) }
  let(:user2) { create(:confirmed_user) }

  before do
    create(:tutorial_membership, user: user1, tutorial: tutorial)
    create(:tutorial_membership, user: user2, tutorial: tutorial)
    Flipper.enable(:assessment_grading)
  end

  after { Flipper.disable(:assessment_grading) }

  describe "#perform" do
    context "with an expired assignment" do
      let!(:assignment) do
        create(:assignment, lecture: lecture,
                            deadline: 1.day.ago,
                            deletion_date: 6.months.from_now)
      end

      it "creates participations for all roster students" do
        expect do
          described_class.new.perform
        end.to change(Assessment::Participation, :count).by(2)

        user_ids = Assessment::Participation.pluck(:user_id)
        expect(user_ids).to contain_exactly(user1.id, user2.id)
      end

      it "sets tutorial_id from roster membership" do
        described_class.new.perform

        Assessment::Participation.find_each do |p|
          expect(p.tutorial_id).to eq(tutorial.id)
        end
      end

      it "creates participations with pending status and nil submitted_at" do
        described_class.new.perform

        Assessment::Participation.find_each do |p|
          expect(p.status).to eq("pending")
          expect(p.submitted_at).to be_nil
        end
      end

      it "is idempotent — running twice does not duplicate" do
        described_class.new.perform

        expect do
          described_class.new.perform
        end.not_to change(Assessment::Participation, :count)
      end

      it "does not overwrite existing participations from submissions" do
        assessment = assignment.assessment
        submitted_at = 2.days.ago

        assessment.assessment_participations.create!(
          user: user1,
          tutorial: tutorial,
          status: :pending,
          submitted_at: submitted_at
        )

        described_class.new.perform

        p1 = Assessment::Participation.find_by(user: user1)
        expect(p1.submitted_at).to be_within(1.second).of(submitted_at)

        expect(Assessment::Participation.count).to eq(2)
      end

      it "backfills new roster user even when stale participation exists" do
        assessment = assignment.assessment
        former_user = create(:confirmed_user)

        assessment.assessment_participations.create!(
          user: former_user,
          tutorial: tutorial,
          status: :pending
        )

        described_class.new.perform

        expect(Assessment::Participation.where(user: [user1, user2]).count)
          .to eq(2)
      end

      it "skips assignments with deadline older than 2 days" do
        old_assignment = create(
          :assignment, lecture: lecture,
                       deadline: 3.days.ago,
                       deletion_date: 6.months.from_now
        )

        expect do
          described_class.new.perform
        end.not_to(change do
          old_assignment.assessment.assessment_participations.count
        end)
      end
    end

    context "with an active assignment" do
      before do
        create(:assignment, lecture: lecture,
                            deadline: 1.week.from_now,
                            deletion_date: 6.months.from_now)
      end

      it "does not create any participations" do
        expect do
          described_class.new.perform
        end.not_to change(Assessment::Participation, :count)
      end
    end

    context "when feature flag is disabled" do
      before { Flipper.disable(:assessment_grading) }

      it "does not create any participations" do
        create(:assignment, lecture: lecture,
                            deadline: 1.day.ago,
                            deletion_date: 6.months.from_now)

        expect do
          described_class.new.perform
        end.not_to change(Assessment::Participation, :count)
      end
    end

    context "with no roster members" do
      before do
        TutorialMembership.destroy_all
      end

      it "does not create any participations" do
        create(:assignment, lecture: lecture,
                            deadline: 1.day.ago,
                            deletion_date: 6.months.from_now)

        expect do
          described_class.new.perform
        end.not_to change(Assessment::Participation, :count)
      end
    end
  end
end
