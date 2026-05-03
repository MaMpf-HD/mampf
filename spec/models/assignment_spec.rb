require "rails_helper"

RSpec.describe(Assignment, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:valid_assignment)).to be_valid
  end

  # test validations

  it "is invalid without a deadline" do
    assignment = FactoryBot.build(:valid_assignment, deadline: nil)
    expect(assignment).to be_invalid
  end

  it "is invalid without a title" do
    assignment = FactoryBot.build(:valid_assignment, title: nil)
    expect(assignment).to be_invalid
  end

  it "is invalid with duplicate title in same lecture" do
    assignment = FactoryBot.create(:valid_assignment, title: "usual BS")
    lecture = assignment.lecture
    new_assignment = FactoryBot.build(:valid_assignment, lecture: lecture,
                                                         title: "usual BS")
    expect(new_assignment).to be_invalid
  end

  it "is invalid with inadmissible accepted filetype" do
    assignment = FactoryBot.build(:valid_assignment, accepted_file_type: ".jpg")
    expect(assignment).to be_invalid
  end

  describe "#past_deadline?" do
    it "returns true when deadline is in the past" do
      assignment = FactoryBot.build(:valid_assignment, :inactive)
      expect(assignment.past_deadline?).to be(true)
    end

    it "returns false when deadline is in the future" do
      assignment = FactoryBot.build(:valid_assignment)
      expect(assignment.past_deadline?).to be(false)
    end
  end

  describe "locked fields after deadline" do
    let!(:assignment) do
      FactoryBot.create(:valid_assignment, deadline: 1.hour.from_now)
    end

    before { Timecop.travel(2.hours.from_now) }
    after { Timecop.return }

    it "prevents changing accepted_file_type" do
      assignment.accepted_file_type = ".zip"
      expect(assignment).to be_invalid
      expect(assignment.errors[:accepted_file_type]).to be_present
    end

    it "allows saving without changing accepted_file_type" do
      assignment.title = "New title"
      expect(assignment).to be_valid
    end

    it "allows extending the deadline forward" do
      assignment.deadline = 2.days.from_now
      expect(assignment).to be_valid
    end
  end

  # test traits
  describe "with lecture" do
    it "has a lecture" do
      assignment = FactoryBot.build(:assignment, :with_lecture)
      expect(assignment.lecture).to be_kind_of(Lecture)
    end
  end

  describe "assessment integration" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:tutorial1) { FactoryBot.create(:tutorial, lecture: lecture) }
    let(:tutorial2) { FactoryBot.create(:tutorial, lecture: lecture) }
    let(:user1) { FactoryBot.create(:confirmed_user) }
    let(:user2) { FactoryBot.create(:confirmed_user) }
    let(:user3) { FactoryBot.create(:confirmed_user) }

    before do
      FactoryBot.create(:tutorial_membership, tutorial: tutorial1, user: user1)
      FactoryBot.create(:tutorial_membership, tutorial: tutorial1, user: user2)
      FactoryBot.create(:tutorial_membership, tutorial: tutorial2, user: user3)
    end

    context "when assessment_grading flag is enabled" do
      before { Flipper.enable(:assessment_grading) }
      after { Flipper.disable(:assessment_grading) }

      it "creates an assessment on assignment creation" do
        assignment = FactoryBot.create(:assignment, lecture: lecture, title: "Homework 1")

        expect(assignment.assessment).to be_present
        expect(assignment.assessment.title).to eq("Homework 1")
        expect(assignment.assessment.requires_points).to be(true)
        expect(assignment.assessment.requires_submission).to be(true)
        expect(assignment.assessment.lecture).to eq(lecture)
      end

      it "does not eagerly seed participations (lazy creation)" do
        assignment = FactoryBot.create(:assignment, lecture: lecture)

        expect(assignment.assessment.assessment_participations.count).to eq(0)
      end
    end

    context "when assessment_grading flag is disabled" do
      before { Flipper.disable(:assessment_grading) }

      it "does not create an assessment" do
        assignment = FactoryBot.create(:assignment, lecture: lecture)

        expect(assignment.assessment).to be_nil
      end

      it "works normally without assessment integration" do
        assignment = FactoryBot.create(:assignment, lecture: lecture, title: "Homework 1")

        expect(assignment).to be_valid
        expect(assignment.title).to eq("Homework 1")
        expect(assignment.lecture).to eq(lecture)
      end
    end
  end

  describe "destructibility" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:assignment) { FactoryBot.create(:assignment, lecture: lecture) }

    context "when assignment has no submissions or grading data" do
      it "is destructible" do
        expect(assignment.destructible?).to be(true)
      end

      it "returns nil for non_destructible_reason" do
        expect(assignment.non_destructible_reason).to be_nil
      end
    end

    context "when assignment has proper submissions" do
      before do
        tutorial = FactoryBot.create(:tutorial, lecture: lecture)
        submission = FactoryBot.create(:submission, :with_manuscript,
                                       assignment: assignment,
                                       tutorial: tutorial)
        FactoryBot.create(:user_submission_join,
                          submission: submission,
                          user: FactoryBot.create(:confirmed_user))
      end

      it "is not destructible" do
        expect(assignment.destructible?).to be(false)
      end

      it "returns :has_submissions as non_destructible_reason" do
        expect(assignment.non_destructible_reason).to eq(:has_submissions)
      end
    end

    context "when assignment has grading data but no submissions" do
      before do
        Flipper.enable(:assessment_grading)
        assignment.reload
      end

      after { Flipper.disable(:assessment_grading) }

      context "with reviewed participation" do
        before do
          FactoryBot.create(:assessment_participation,
                            assessment: assignment.assessment,
                            status: :reviewed)
        end

        it "is not destructible" do
          expect(assignment.destructible?).to be(false)
        end

        it "returns :has_grading_data as non_destructible_reason" do
          expect(assignment.non_destructible_reason).to eq(:has_grading_data)
        end
      end

      context "with exempt participation" do
        before do
          FactoryBot.create(:assessment_participation,
                            assessment: assignment.assessment,
                            status: :exempt)
        end

        it "is not destructible" do
          expect(assignment.destructible?).to be(false)
        end

        it "returns :has_grading_data as non_destructible_reason" do
          expect(assignment.non_destructible_reason).to eq(:has_grading_data)
        end
      end

      context "with task points entered" do
        before do
          participation = FactoryBot.create(:assessment_participation,
                                            assessment: assignment.assessment)
          task = FactoryBot.create(:assessment_task, assessment: assignment.assessment)
          FactoryBot.create(:assessment_task_point,
                            assessment_participation: participation,
                            task: task,
                            points: 5.0)
        end

        it "is not destructible" do
          expect(assignment.destructible?).to be(false)
        end

        it "returns :has_grading_data as non_destructible_reason" do
          expect(assignment.non_destructible_reason).to eq(:has_grading_data)
        end
      end

      context "with points_total set" do
        before do
          FactoryBot.create(:assessment_participation,
                            assessment: assignment.assessment,
                            points_total: 10.0)
        end

        it "is not destructible" do
          expect(assignment.destructible?).to be(false)
        end

        it "returns :has_grading_data as non_destructible_reason" do
          expect(assignment.non_destructible_reason).to eq(:has_grading_data)
        end
      end
    end
  end
end
