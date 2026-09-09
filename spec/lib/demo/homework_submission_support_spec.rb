require "rails_helper"

# The demo hands sheets in with `update_all`, which skips the callback that
# would otherwise stamp the gradebook. What it stamps is the point of these
# examples: a hand-in that nobody recorded shows up on the student's page in
# red, and a stamp on somebody who was excused undoes an entry a tutor made.
RSpec.describe(Demo::HomeworkSubmissionSupport, type: :model) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture) }
  let(:assessment) { assignment.assessment }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:submission) do
    create(:submission, assignment: assignment, tutorial: tutorial,
                        last_modification_by_users_at: 1.day.ago)
  end

  def participation_for(user, *traits)
    create(:assessment_participation, *traits, assessment: assessment,
                                               user: user)
  end

  def record_hand_in!(team)
    Demo::SetupSupport.send(:record_hand_in!, assignment, team, submission)
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
      Demo::SetupSupport.send(:hand_in_time, sheet, late: late)
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

  it "stamps the hand-in the demo just built" do
    user = create(:confirmed_user)
    participation = participation_for(user, :pending)

    record_hand_in!([user])

    expect(participation.reload.submitted_at)
      .to be_within(1.second).of(submission.last_modification_by_users_at)
  end

  # `Assessment::AbsenceHandling` clears the stamp when it sets either status,
  # and it means it: a stamp back would say the sheet was handed in after all.
  it "leaves somebody who was marked absent or exempt alone" do
    absent = create(:confirmed_user)
    exempt = create(:confirmed_user)
    absent_participation = participation_for(absent, :absent)
    exempt_participation = participation_for(exempt, :exempt)

    record_hand_in!([absent, exempt])

    expect(absent_participation.reload.submitted_at).to be_nil
    expect(exempt_participation.reload.submitted_at).to be_nil
  end
end
