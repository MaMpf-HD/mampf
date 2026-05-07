require "rails_helper"

RSpec.describe(Exam, type: :model) do
  it "has a valid factory" do
    expect(build(:exam)).to be_valid
  end

  describe "validations" do
    it "is invalid without a title" do
      expect(build(:exam, title: nil)).to be_invalid
    end

    it "is invalid without a lecture" do
      expect(build(:exam, lecture: nil)).to be_invalid
    end

    it "is valid without a date (oral exam)" do
      expect(build(:exam, :oral)).to be_valid
    end

    it "is invalid with negative capacity" do
      expect(build(:exam, capacity: -1)).to be_invalid
    end

    it "is invalid with zero capacity" do
      expect(build(:exam, capacity: 0)).to be_invalid
    end

    it "is valid with positive capacity" do
      expect(build(:exam, capacity: 100)).to be_valid
    end

    it "is valid with nil capacity (unlimited)" do
      expect(build(:exam, capacity: nil)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      exam = create(:exam)
      expect(exam.lecture).to be_a(Lecture)
    end
  end

  describe "concerns" do
    it "includes Assessment::Pointable" do
      expect(Exam.ancestors).to include(Assessment::Pointable)
    end

    it "includes Assessment::Gradable" do
      expect(Exam.ancestors).to include(Assessment::Gradable)
    end
  end

  describe "assessment setup" do
    context "when assessment_grading feature flag is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(true)
      end

      it "creates an assessment after creation" do
        exam = nil
        expect do
          exam = create(:exam)
        end.to change(Assessment::Assessment, :count).by(1)

        expect(exam.assessment).to be_present
      end
    end

    context "when assessment_grading feature flag is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(false)
      end

      it "does not create an assessment after creation" do
        expect do
          create(:exam)
        end.not_to change(Assessment::Assessment, :count)
      end
    end
  end
end
