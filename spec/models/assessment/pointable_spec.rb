require "rails_helper"

RSpec.describe(Assessment::Pointable) do
  let(:lecture) { FactoryBot.create(:lecture) }
  let(:assignment) { FactoryBot.create(:assignment, lecture: lecture, title: "Homework 1") }

  describe "#ensure_pointbook!" do
    it "creates an assessment with requires_points: true" do
      expect(assignment.assessment).to be_nil

      result = assignment.ensure_pointbook!(requires_submission: true)

      expect(result).to be_persisted
      expect(result.requires_points).to be(true)
      expect(result.requires_submission).to be(true)
      expect(result.lecture).to eq(lecture)
    end

    it "defaults requires_submission to false" do
      result = assignment.ensure_pointbook!

      expect(result.requires_submission).to be(false)
    end

    it "is idempotent" do
      assignment.ensure_pointbook!(requires_submission: true)
      original_id = assignment.assessment.id

      assignment.ensure_pointbook!(requires_submission: false)

      expect(assignment.assessment.id).to eq(original_id)
      expect(assignment.assessment.requires_submission).to be(false)
    end
  end

  describe "integration with Assignment" do
    context "when assessment_grading flag is enabled" do
      before { Flipper.enable(:assessment_grading) }
      after { Flipper.disable(:assessment_grading) }

      it "automatically creates pointbook on assignment creation" do
        new_assignment = FactoryBot.create(:assignment, lecture: lecture)

        expect(new_assignment.assessment).to be_present
        expect(new_assignment.assessment.requires_points).to be(true)
        expect(new_assignment.assessment.requires_submission).to be(true)
      end
    end
  end
end
