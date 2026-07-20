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
end
