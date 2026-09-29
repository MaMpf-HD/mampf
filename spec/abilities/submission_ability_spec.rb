require "rails_helper"

RSpec.describe(SubmissionAbility) do
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture, deadline: 3.days.from_now) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:ability) { described_class.new(student) }

  describe "uploading a manuscript" do
    it "needs a seat in the lecture for a new hand-in" do
      hand_in = Submission.new(assignment: assignment)
      expect(ability.can?(:upload_manuscript, hand_in)).to be(false)

      tutorial.add_user_to_roster!(student)

      expect(described_class.new(student).can?(:upload_manuscript, hand_in)).to be(true)
    end

    it "needs a seat to replace the file of the student's own hand-in too" do
      submission = create(:submission, assignment: assignment, tutorial: tutorial)
      submission.users << student
      expect(ability.can?(:upload_manuscript, submission)).to be(false)

      create(:tutorial, lecture: lecture).add_user_to_roster!(student)

      expect(described_class.new(student).can?(:upload_manuscript, submission)).to be(true)
    end

    it "refuses a hand-in of somebody else, seat or not" do
      tutorial.add_user_to_roster!(student)
      submission = create(:submission, assignment: assignment, tutorial: tutorial)

      expect(ability.can?(:upload_manuscript, submission)).to be(false)
    end
  end

  describe "correcting a hand-in" do
    let(:submission) { create(:submission, assignment: assignment, tutorial: tutorial) }

    it "lets the group's tutor correct and decide on a late hand-in" do
      tutorial.tutors << student
      ability = described_class.new(student)

      expect(ability.can?(:add_correction, submission)).to be(true)
      expect(ability.can?(:delete_correction, submission)).to be(true)
      expect(ability.can?(:accept, submission)).to be(true)
    end

    it "lets the lecture's teacher correct, but not decide on a late hand-in" do
      ability = described_class.new(lecture.teacher)

      expect(ability.can?(:add_correction, submission)).to be(true)
      expect(ability.can?(:delete_correction, submission)).to be(true)
      expect(ability.can?(:accept, submission)).to be(false)
      expect(ability.can?(:reject, submission)).to be(false)
    end

    it "lets the lecture's editors correct" do
      lecture.editors << student

      expect(described_class.new(student).can?(:add_correction, submission)).to be(true)
    end

    it "refuses a tutor of another group" do
      create(:tutorial, lecture: lecture).tutors << student

      expect(described_class.new(student).can?(:add_correction, submission)).to be(false)
    end
  end
end
