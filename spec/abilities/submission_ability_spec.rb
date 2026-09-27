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
end
