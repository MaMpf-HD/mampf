require "rails_helper"

RSpec.describe(Assessment::Assessable) do
  let(:lecture) { FactoryBot.create(:lecture) }

  shared_examples "an assessable model" do
    describe "#ensure_assessment!" do
      it "creates an assessment when none exists" do
        expect(assessable.assessment).to be_nil

        result = assessable.ensure_assessment!(
          title: "Test Assessment",
          requires_points: true,
          requires_submission: false
        )

        expect(result).to be_persisted
        expect(result.title).to eq("Test Assessment")
        expect(result.requires_points).to be(true)
        expect(result.requires_submission).to be(false)
      end

      it "is idempotent and updates existing assessment" do
        assessable.ensure_assessment!(
          title: "Original Title",
          requires_points: true
        )

        original_id = assessable.assessment.id

        assessable.ensure_assessment!(
          title: "Updated Title",
          requires_points: false
        )

        expect(assessable.assessment.id).to eq(original_id)
        expect(assessable.assessment.title).to eq("Updated Title")
        expect(assessable.assessment.requires_points).to be(false)
      end

      it "sets lecture from assessable if available" do
        result = assessable.ensure_assessment!(
          title: "Test",
          requires_points: false
        )

        expect(result.lecture).to eq(assessable.lecture)
      end

      it "sets optional fields only if provided" do
        due_date = 1.week.from_now
        visible_date = Time.current

        result = assessable.ensure_assessment!(
          title: "Test",
          requires_points: true,
          due_at: due_date,
          visible_from: visible_date
        )

        expect(result.due_at).to be_within(1.second).of(due_date)
        expect(result.visible_from).to be_within(1.second).of(visible_date)
      end

      it "does not overwrite optional fields if not provided" do
        original_due = 1.week.from_now

        assessable.ensure_assessment!(
          title: "Test",
          requires_points: true,
          due_at: original_due
        )

        assessable.ensure_assessment!(
          title: "Updated Test",
          requires_points: true
        )

        expect(assessable.assessment.due_at).to be_within(1.second).of(original_due)
      end

      it "can update optional fields when explicitly provided" do
        original_due = 1.week.from_now
        new_due = 2.weeks.from_now

        assessable.ensure_assessment!(
          title: "Test",
          requires_points: true,
          due_at: original_due
        )

        assessable.ensure_assessment!(
          title: "Test",
          requires_points: true,
          due_at: new_due
        )

        expect(assessable.assessment.due_at).to be_within(1.second).of(new_due)
      end
    end
  end

  describe "when included in Assignment" do
    let(:assessable) { FactoryBot.create(:assignment, lecture: lecture) }

    it_behaves_like "an assessable model"

    describe "#seed_participations_from_roster!" do
      it "implements the method (does not raise NotImplementedError)" do
        expect { assessable.seed_participations_from_roster! }.not_to raise_error
      end
    end
  end

  describe "when included in Talk" do
    let(:seminar_lecture) { FactoryBot.create(:lecture, sort: "seminar") }
    let(:assessable) { FactoryBot.create(:talk, lecture: seminar_lecture) }

    it_behaves_like "an assessable model"

    describe "#seed_participations_from_roster!" do
      it "implements the method (does not raise NotImplementedError)" do
        expect { assessable.seed_participations_from_roster! }.not_to raise_error
      end
    end
  end
end
