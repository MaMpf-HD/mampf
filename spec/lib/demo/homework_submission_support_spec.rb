require "rails_helper"

# When the demo dates its hand-ins. The stamping that goes with them lives in
# `Demo::HandInSupport` and is covered there.
RSpec.describe(Demo::HomeworkSubmissionSupport, type: :model) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture) }
  let(:assessment) { assignment.assessment }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:submission) do
    create(:submission, assignment: assignment, tutorial: tutorial,
                        last_modification_by_users_at: 1.day.ago)
  end

  # The demo dates its hand-ins around the deadline they belong to, and the
  # last sheet has none behind it: its deadline is still ahead, so anything
  # measured from it would be a hand-in from the future.
  describe "when the sheet is still open" do
    # A past deadline goes through the :expired trait, which is what gets it
    # past the validation that refuses one.
    def hand_in_time(deadline, late:)
      sheet =
        if deadline.future?
          create(:assignment, lecture: lecture, deadline: deadline)
        else
          create(:assignment, :expired, lecture: lecture,
                                        expired_since: (Time.zone.now - deadline).seconds)
        end
      Demo::SetupSupport.send(:handed_in_at, sheet, late: late)
    end

    it "hands in before now rather than around a deadline still to come" do
      expect(hand_in_time(5.days.from_now, late: false)).to be < Time.zone.now
    end

    # Nothing can be late before its own deadline, and the demo hands in late
    # every twentieth time.
    it "is not late either, whatever the rotation says" do
      expect(hand_in_time(5.days.from_now, late: true)).to be < Time.zone.now
    end

    it "still dates a closed sheet around its own deadline" do
      deadline = 1.week.ago

      expect(hand_in_time(deadline, late: true)).to be > deadline
      expect(hand_in_time(deadline, late: false)).to be < deadline
    end
  end
end
