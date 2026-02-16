require "rails_helper"

RSpec.describe(Assessment::AbsenceHandling) do
  let(:test_service) do
    Class.new { include Assessment::AbsenceHandling }.new
  end

  let(:participation) { create(:assessment_participation, :pending) }

  describe "#mark_absent" do
    it "sets status to absent and clears submitted_at" do
      test_service.mark_absent(participation)

      participation.reload
      expect(participation.status).to eq("absent")
      expect(participation.submitted_at).to be_nil
    end

    it "leaves points and grade nil" do
      test_service.mark_absent(participation)

      participation.reload
      expect(participation.points_total).to be_nil
      expect(participation.grade_numeric).to be_nil
    end

    it "allows transition from exempt to absent" do
      exempt = create(:assessment_participation, :exempt)

      expect { test_service.mark_absent(exempt) }.not_to raise_error
      expect(exempt.reload.status).to eq("absent")
    end

    it "raises on transition from reviewed to absent" do
      reviewed = create(:assessment_participation, :reviewed)

      expect { test_service.mark_absent(reviewed) }
        .to raise_error(Assessment::AbsenceHandling::InvalidTransitionError,
                        /would discard grading data/)
    end
  end

  describe "#mark_exempt" do
    it "sets status to exempt and clears submitted_at" do
      test_service.mark_exempt(participation)

      participation.reload
      expect(participation.status).to eq("exempt")
      expect(participation.submitted_at).to be_nil
    end

    it "stores the note when provided" do
      test_service.mark_exempt(participation, note: "Medical cert #1234")

      expect(participation.reload.note).to eq("Medical cert #1234")
    end

    it "does not overwrite note when not provided" do
      participation.update!(note: "Existing note")

      test_service.mark_exempt(participation)

      expect(participation.reload.note).to eq("Existing note")
    end

    it "allows transition from absent to exempt" do
      absent = create(:assessment_participation, :absent)

      expect { test_service.mark_exempt(absent, note: "Late excuse") }
        .not_to raise_error
      expect(absent.reload.status).to eq("exempt")
      expect(absent.note).to eq("Late excuse")
    end

    it "raises on transition from reviewed to exempt" do
      reviewed = create(:assessment_participation, :reviewed)

      expect { test_service.mark_exempt(reviewed) }
        .to raise_error(Assessment::AbsenceHandling::InvalidTransitionError,
                        /would discard grading data/)
    end
  end
end
