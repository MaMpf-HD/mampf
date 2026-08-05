require "rails_helper"

RSpec.describe(Assessment::Assessable) do
  let(:lecture) { FactoryBot.create(:lecture) }

  shared_examples "an assessable model" do
    describe "#ensure_assessment!" do
      it "creates an assessment when none exists" do
        expect(assessable.assessment).to be_nil

        result = assessable.ensure_assessment!(
          requires_points: true,
          requires_submission: false
        )

        expect(result).to be_persisted
        expect(result.title).to eq(assessable.title)
        expect(result.requires_points).to be(true)
        expect(result.requires_submission).to be(false)
      end

      it "is idempotent and updates existing assessment" do
        assessable.ensure_assessment!(
          requires_points: true
        )

        original_id = assessable.assessment.id

        assessable.ensure_assessment!(
          requires_points: false
        )

        expect(assessable.assessment.id).to eq(original_id)
        expect(assessable.assessment.requires_points).to be(false)
      end

      it "sets lecture from assessable if available" do
        result = assessable.ensure_assessment!(
          requires_points: false
        )

        expect(result.lecture).to eq(assessable.lecture)
      end

      it "delegates title to assessable" do
        result = assessable.ensure_assessment!(requires_points: true)

        expect(result.title).to eq(assessable.title)
      end
    end
  end

  describe "when included in Assignment" do
    let(:assessable) { FactoryBot.create(:assignment, lecture: lecture) }

    it_behaves_like "an assessable model"
  end

  describe "when included in Talk" do
    let(:seminar_lecture) { FactoryBot.create(:lecture, sort: "seminar") }
    let(:assessable) { FactoryBot.create(:talk, lecture: seminar_lecture) }

    it_behaves_like "an assessable model"
  end

  describe "lecture immutability" do
    # The assessment stores lecture_id too, so a move would leave that copy
    # pointing at the old lecture with nothing to notice it.
    let(:assignment) { FactoryBot.create(:assignment, lecture: lecture) }

    it "refuses to move to another lecture" do
      assignment.lecture = FactoryBot.create(:lecture)

      expect(assignment).to be_invalid
      expect(assignment.errors.added?(:lecture_id, :immutable)).to be(true)
    end

    it "allows saving without touching the lecture" do
      assignment.title = "Übungsblatt 8"

      expect(assignment).to be_valid
    end

    it "does not interfere with creating an assessable" do
      expect(FactoryBot.build(:assignment, lecture: lecture)).to be_valid
    end
  end
end
