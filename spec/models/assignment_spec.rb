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

  # test method - NEEDS TO BE DONE
end
