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

      it "seeds participations from all lecture tutorials" do
        assignment = FactoryBot.create(:assignment, lecture: lecture)

        expect(assignment.assessment.assessment_participations.count).to eq(3)

        user_ids = assignment.assessment.assessment_participations.pluck(:user_id)
        expect(user_ids).to contain_exactly(user1.id, user2.id, user3.id)
      end

      it "sets tutorial_id correctly on participations" do
        assignment = FactoryBot.create(:assignment, lecture: lecture)

        participation1 = assignment.assessment.assessment_participations.find_by(user_id: user1.id)
        participation2 = assignment.assessment.assessment_participations.find_by(user_id: user2.id)
        participation3 = assignment.assessment.assessment_participations.find_by(user_id: user3.id)

        expect(participation1.tutorial_id).to eq(tutorial1.id)
        expect(participation2.tutorial_id).to eq(tutorial1.id)
        expect(participation3.tutorial_id).to eq(tutorial2.id)
      end

      it "initializes participations with default values" do
        assignment = FactoryBot.create(:assignment, lecture: lecture)

        participation = assignment.assessment.assessment_participations.first
        expect(participation.status).to eq("not_started")
        expect(participation.points_total).to eq(0.0)
      end

      it "sets due_at from assignment deadline" do
        deadline = 1.week.from_now
        assignment = FactoryBot.create(:assignment, lecture: lecture, deadline: deadline)

        expect(assignment.assessment.due_at).to be_within(1.second).of(deadline)
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

    describe "#seed_participations_from_roster!" do
      it "is idempotent" do
        Flipper.enable(:assessment_grading)
        assignment = FactoryBot.create(:assignment, lecture: lecture)
        Flipper.disable(:assessment_grading)

        initial_count = assignment.assessment.assessment_participations.count
        expect(initial_count).to eq(3)

        assignment.seed_participations_from_roster!

        expect(assignment.assessment.assessment_participations.count).to eq(3)
      end

      it "adds new students if they join later" do
        Flipper.enable(:assessment_grading)
        assignment = FactoryBot.create(:assignment, lecture: lecture)
        Flipper.disable(:assessment_grading)

        expect(assignment.assessment.assessment_participations.count).to eq(3)

        new_user = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:tutorial_membership, tutorial: tutorial1, user: new_user)

        assignment.seed_participations_from_roster!

        expect(assignment.assessment.assessment_participations.count).to eq(4)

        new_participation = assignment.assessment.assessment_participations
                                      .find_by(user_id: new_user.id)
        expect(new_participation.tutorial_id).to eq(tutorial1.id)
      end
    end
  end

  # test method - NEEDS TO BE DONE
end
