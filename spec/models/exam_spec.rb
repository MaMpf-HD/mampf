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

  describe "#registrable_by?" do
    let(:exam) { create(:exam) }
    let(:user) { create(:confirmed_user) }

    it "lets anybody register when the registration checks no admission" do
      expect(exam.registrable_by?(user)).to be(true)
    end

    context "when the registration checks the admission" do
      before do
        create(:registration_policy, :student_performance,
               registration_campaign: exam.registration_campaign)
      end

      it "lets a member of the lecture register" do
        create(:lecture_membership, lecture: exam.lecture, user: user)

        expect(exam.registrable_by?(user)).to be(true)
      end

      # The admission check needs a decision; without one, the finalization
      # would stop at this person.
      it "keeps out somebody who only bookmarked the lecture" do
        create(:lecture_bookmark, lecture: exam.lecture, user: user)

        expect(exam.registrable_by?(user)).to be(false)
      end

      it "lets someone who left with an admission decision register" do
        create(:lecture_membership, lecture: exam.lecture, user: user).exclude!(by: user)
        create(:student_performance_certification, :passed, lecture: exam.lecture, user: user)

        expect(exam.registrable_by?(user)).to be(true)
      end

      # A pending admission is no decision, and the finalization would stop at
      # it.
      it "keeps out someone who left with the admission still pending" do
        create(:lecture_membership, lecture: exam.lecture, user: user).exclude!(by: user)
        create(:student_performance_certification, :pending, lecture: exam.lecture, user: user)

        expect(exam.registrable_by?(user)).to be(false)
      end
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
    it "creates an assessment after creation" do
      exam = nil
      expect do
        exam = create(:exam)
      end.to change(Assessment::Assessment, :count).by(1)

      expect(exam.assessment).to be_present
    end
  end
end
