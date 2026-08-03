require "rails_helper"

RSpec.describe(Assessment::Gradable) do
  let(:lecture) { FactoryBot.create(:lecture, :is_seminar) }
  let(:talk) { FactoryBot.create(:talk, lecture: lecture) }
  let(:speaker) { FactoryBot.create(:confirmed_user) }
  let(:teacher) { FactoryBot.create(:confirmed_user) }

  before { talk.ensure_gradebook! }

  describe "#set_grade!" do
    it "records a numeric grade as a number" do
      talk.set_grade!(user: speaker, value: "1.3", grader: teacher)

      participation = talk.assessment.assessment_participations.find_by(user: speaker)
      expect(participation.grade_numeric).to eq(1.3)
      expect(participation.grade_text).to be_nil
      expect(participation).to be_reviewed
      expect(participation.grader).to eq(teacher)
    end

    it "records a word as text" do
      talk.set_grade!(user: speaker, value: "passed", grader: teacher)

      participation = talk.assessment.assessment_participations.find_by(user: speaker)
      expect(participation.grade_text).to eq("passed")
      expect(participation.grade_numeric).to be_nil
    end

    # `^` and `$` match line boundaries in Ruby, so a value with a newline in it
    # would otherwise be filed away as the number on its first line.
    it "does not read a multiline value as a number" do
      talk.set_grade!(user: speaker, value: "1.0\nand something else", grader: teacher)

      participation = talk.assessment.assessment_participations.find_by(user: speaker)
      expect(participation.grade_numeric).to be_nil
      expect(participation.grade_text).to eq("1.0\nand something else")
    end

    it "overwrites the earlier grade rather than adding a participation" do
      talk.set_grade!(user: speaker, value: "2.0", grader: teacher)

      expect do
        talk.set_grade!(user: speaker, value: "1.0", grader: teacher)
      end.not_to change(Assessment::Participation, :count)

      participation = talk.assessment.assessment_participations.find_by(user: speaker)
      expect(participation.grade_numeric).to eq(1.0)
    end

    it "refuses to grade without a gradebook" do
      other_talk = FactoryBot.create(:talk, lecture: lecture)
      other_talk.assessment&.destroy

      expect { other_talk.reload.set_grade!(user: speaker, value: "1.0") }
        .to raise_error(RuntimeError, /No gradebook/)
    end
  end
end
