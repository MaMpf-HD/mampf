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
