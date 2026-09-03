require "rails_helper"

RSpec.describe(Assessment::GradeEntryService, type: :model) do
  let(:assessment) { FactoryBot.create(:assessment, :gradable) }
  let(:participation) { FactoryBot.create(:assessment_participation, assessment: assessment) }
  let(:grader) do
    FactoryBot.create(:confirmed_user, locale: :en)
  end

  describe ".set_grade" do
    context "when the assessable is not Gradable" do
      let(:non_gradable_assessment) do
        assignment = FactoryBot.create(:assignment, :with_lecture)
        FactoryBot.create(:assessment, assessable: assignment, lecture: assignment.lecture)
      end
      let(:non_gradable_participation) do
        FactoryBot.create(:assessment_participation, assessment: non_gradable_assessment)
      end
      let(:grade_info) { described_class.build_grade_info(grade_numeric: 1.0) }

      it "raises GradeEntryError" do
        expect do
          described_class.set_grade(non_gradable_participation, grade_info, grader)
        end.to raise_error(Assessment::GradeEntryService::GradeEntryError)
      end

      it "does not update the participation" do
        expect do
          described_class.set_grade(non_gradable_participation, grade_info, grader)
        rescue Assessment::GradeEntryService::GradeEntryError
          nil
        end.not_to(change { non_gradable_participation.reload.attributes })
      end
    end

    context "with a valid numeric grade" do
      let(:grade_info) { described_class.build_grade_info(grade_numeric: "1.3") }

      it "updates grade_numeric" do
        described_class.set_grade(participation, grade_info, grader, "great job")
        expect(participation.reload.grade_numeric).to eq(1.3)
      end

      it "sets grader_id" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.grader_id).to eq(grader.id)
      end

      it "sets graded_at" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.graded_at).to be_present
      end

      it "sets status to reviewed" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.status).to eq("reviewed")
      end

      it "sets the note when a comment is given" do
        described_class.set_grade(participation, grade_info, grader, "great job")
        expect(participation.reload.note).to eq("great job")
      end

      it "keeps the existing note when no comment is given" do
        participation.update!(note: "existing note")
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.note).to eq("existing note")
      end
    end

    context "with a valid grade_text" do
      let(:grade_info) { described_class.build_grade_info(grade_text: "pass") }

      it "updates grade_text" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.grade_text).to eq("pass")
      end

      it "sets status to reviewed" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.status).to eq("reviewed")
      end
    end

    context "with an invalid numeric grade" do
      let(:grade_info) { described_class.build_grade_info(grade_numeric: "6.0") }

      it "raises GradeEntryError" do
        expect do
          described_class.set_grade(participation, grade_info, grader)
        end.to raise_error(Assessment::GradeEntryService::GradeEntryError)
      end

      it "does not update the participation" do
        expect do
          described_class.set_grade(participation, grade_info, grader)
        rescue Assessment::GradeEntryService::GradeEntryError
          nil
        end.not_to(change { participation.reload.attributes })
      end
    end

    context "with blank grade (unscoring)" do
      let(:grade_info) { described_class.build_grade_info }

      before do
        participation.update!(grade_numeric: 1.0, status: :reviewed)
      end

      it "clears grade_numeric" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.grade_numeric).to be_nil
      end

      it "sets status to pending" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.status).to eq("pending")
      end
    end

    context "when participation is exempt" do
      before { participation.update!(status: :exempt) }

      let(:grade_info) { described_class.build_grade_info(grade_numeric: "1.0") }

      it "retains the exempt status regardless of grade" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.status).to eq("exempt")
      end

      it "still updates the grade value" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.grade_numeric).to eq(1.0)
      end
    end

    context "when participation is absent" do
      before { participation.update!(status: :absent) }

      let(:grade_info) { described_class.build_grade_info(grade_numeric: "1.0") }

      it "retains the absent status regardless of grade" do
        described_class.set_grade(participation, grade_info, grader)
        expect(participation.reload.status).to eq("absent")
      end
    end
  end

  describe ".calculate_status" do
    context "when participation is exempt" do
      before { participation.status = :exempt }

      it "returns the current status" do
        result = described_class.calculate_status(participation, { grade_numeric: 1.0 })
        expect(result).to eq("exempt")
      end
    end

    context "when participation is absent" do
      before { participation.status = :absent }

      it "returns the current status" do
        result = described_class.calculate_status(participation, { grade_numeric: nil })
        expect(result).to eq("absent")
      end
    end

    context "when grade_numeric is present" do
      it "returns :reviewed" do
        result = described_class.calculate_status(participation, { grade_numeric: 1.0 })
        expect(result).to eq(:reviewed)
      end
    end

    context "when grade_text is present" do
      it "returns :reviewed" do
        result = described_class.calculate_status(participation, { grade_text: "pass" })
        expect(result).to eq(:reviewed)
      end
    end

    context "when neither grade_numeric nor grade_text is present" do
      it "returns :pending" do
        result = described_class.calculate_status(participation,
                                                  { grade_numeric: nil, grade_text: nil })
        expect(result).to eq(:pending)
      end
    end
  end

  describe ".build_grade_info" do
    it "returns a hash with grade_numeric and grade_text" do
      result = described_class.build_grade_info(grade_numeric: 1.0, grade_text: "pass")
      expect(result).to eq({ grade_numeric: 1.0, grade_text: "pass" })
    end

    it "defaults both keys to nil when not given" do
      result = described_class.build_grade_info
      expect(result).to eq({ grade_numeric: nil, grade_text: nil })
    end

    it "allows only grade_numeric to be set" do
      result = described_class.build_grade_info(grade_numeric: 2.3)
      expect(result).to eq({ grade_numeric: 2.3, grade_text: nil })
    end

    it "allows only grade_text to be set" do
      result = described_class.build_grade_info(grade_text: "fail")
      expect(result).to eq({ grade_numeric: nil, grade_text: "fail" })
    end
  end

  describe ".validate_grade_info" do
    context "with a valid numeric grade as a string" do
      it "converts it to a float" do
        result = described_class.validate_grade_info(grade_numeric: "1.7")
        expect(result[:grade_numeric]).to eq(1.7)
      end

      it "preserves grade_text" do
        result = described_class.validate_grade_info(grade_numeric: "1.7", grade_text: "pass")
        expect(result[:grade_text]).to eq("pass")
      end
    end

    context "with a valid numeric grade as a number" do
      it "accepts it" do
        result = described_class.validate_grade_info(grade_numeric: 3.7)
        expect(result[:grade_numeric]).to eq(3.7)
      end
    end

    it "accepts each value in VALID_GRADES_NUMERIC" do
      Assessment::GradeEntryService::VALID_GRADES_NUMERIC.each do |grade|
        result = described_class.validate_grade_info(grade_numeric: grade.to_s)
        expect(result[:grade_numeric]).to eq(grade)
      end
    end

    context "with a numeric grade not in the valid list" do
      it "raises GradeEntryError" do
        expect do
          described_class.validate_grade_info(grade_numeric: "2.5")
        end.to raise_error(Assessment::GradeEntryService::GradeEntryError,
                           /Invalid grade|Ungültiger Notenwert/)
      end
    end

    context "with a non-numeric grade string" do
      it "raises GradeEntryError" do
        expect do
          described_class.validate_grade_info(grade_numeric: "abc")
        end.to raise_error(Assessment::GradeEntryService::GradeEntryError)
      end
    end

    context "with a blank grade_numeric" do
      it "returns nil grade_numeric without raising" do
        result = described_class.validate_grade_info(grade_numeric: "", grade_text: "pass")
        expect(result[:grade_numeric]).to be_nil
      end

      it "preserves grade_text" do
        result = described_class.validate_grade_info(grade_numeric: "", grade_text: "pass")
        expect(result[:grade_text]).to eq("pass")
      end
    end

    context "with a nil grade_numeric" do
      it "returns nil grade_numeric without raising" do
        result = described_class.validate_grade_info(grade_numeric: nil, grade_text: "fail")
        expect(result[:grade_numeric]).to be_nil
      end
    end

    context "with whitespace-only grade_numeric" do
      it "treats it as blank and does not raise" do
        result = described_class.validate_grade_info(grade_numeric: "   ", grade_text: "pass")
        expect(result[:grade_numeric]).to be_nil
      end
    end

    context "with a negative numeric grade" do
      it "raises GradeEntryError since it's not in VALID_GRADES_NUMERIC" do
        expect do
          described_class.validate_grade_info(grade_numeric: "-1.0")
        end.to raise_error(Assessment::GradeEntryService::GradeEntryError)
      end
    end
  end
end
