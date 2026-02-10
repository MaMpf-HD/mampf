require "rails_helper"

RSpec.describe(Assessment::Gradable) do
  let(:seminar_lecture) { FactoryBot.create(:lecture, sort: "seminar") }
  let(:talk) { FactoryBot.create(:talk, lecture: seminar_lecture, title: "Topology Talk") }
  let(:user) { FactoryBot.create(:confirmed_user) }
  let(:grader) { FactoryBot.create(:confirmed_user) }

  describe "#ensure_gradebook!" do
    it "creates an assessment with requires_points: false" do
      expect(talk.assessment).to be_nil

      result = talk.ensure_gradebook!

      expect(result).to be_persisted
      expect(result.requires_points).to be(false)
      expect(result.requires_submission).to be(false)
      expect(result.lecture).to eq(seminar_lecture)
    end

    it "preserves requires_points: true if already set" do
      talk.ensure_assessment!(requires_points: true, requires_submission: false)
      expect(talk.assessment.requires_points).to be(true)

      talk.ensure_gradebook!

      expect(talk.assessment.requires_points).to be(true)
    end

    it "is idempotent" do
      talk.ensure_gradebook!
      original_id = talk.assessment.id

      talk.ensure_gradebook!

      expect(talk.assessment.id).to eq(original_id)
    end
  end

  describe "#set_grade!" do
    before do
      talk.ensure_gradebook!
    end

    it "creates a participation and sets the grade" do
      expect do
        talk.set_grade!(user: user, value: "1.3", grader: grader)
      end.to change(Assessment::Participation, :count).by(1)

      participation = talk.assessment.assessment_participations.find_by(user: user)
      expect(participation.grade_numeric).to eq(1.3)
      expect(participation.grader_id).to eq(grader.id)
      expect(participation.status).to eq("reviewed")
      expect(participation.graded_at).to be_present
    end

    it "updates existing participation instead of creating duplicate" do
      talk.set_grade!(user: user, value: "2.0", grader: grader)

      expect do
        talk.set_grade!(user: user, value: "1.7", grader: grader)
      end.not_to change(Assessment::Participation, :count)

      participation = talk.assessment.assessment_participations.find_by(user: user)
      expect(participation.grade_numeric).to eq(1.7)
    end

    it "works without a grader" do
      talk.set_grade!(user: user, value: "1.0")

      participation = talk.assessment.assessment_participations.find_by(user: user)
      expect(participation.grade_numeric).to eq(1.0)
      expect(participation.grader_id).to be_nil
    end

    it "handles text grades (Pass/Fail)" do
      talk.set_grade!(user: user, value: "Pass")

      participation = talk.assessment.assessment_participations.find_by(user: user)
      expect(participation.grade_text).to eq("Pass")
      expect(participation.grade_numeric).to be_nil
    end

    it "allows both numeric and text grades (German + ECTS)" do
      talk.set_grade!(user: user, grade_numeric: 1.7, grade_text: "B", grader: grader)

      participation = talk.assessment.assessment_participations.find_by(user: user)
      expect(participation.grade_numeric).to eq(1.7)
      expect(participation.grade_text).to eq("B")
    end

    it "raises error when assessment does not exist" do
      talk_without_assessment = FactoryBot.create(:talk, lecture: seminar_lecture)

      expect do
        talk_without_assessment.set_grade!(user: user, value: "1.0")
      end.to raise_error(/No gradebook/)
    end
  end

  describe "integration with Talk" do
    context "when assessment_grading flag is enabled" do
      before { Flipper.enable(:assessment_grading) }
      after { Flipper.disable(:assessment_grading) }

      it "automatically creates gradebook on talk creation" do
        new_talk = FactoryBot.create(:talk, lecture: seminar_lecture)

        expect(new_talk.assessment).to be_present
        expect(new_talk.assessment.requires_points).to be(false)
        expect(new_talk.assessment.requires_submission).to be(false)
      end
    end
  end
end
