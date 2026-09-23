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

  # A team is marked as one. The gradebook rolls per person, so a pair can
  # arrive with one member marked and one not; after the hand-in they agree.
  describe "marking a team" do
    let(:sheet) { create(:assignment, :expired, lecture: lecture) }
    let(:task) { create(:assessment_task, assessment: sheet.assessment, max_points: 10) }
    let(:marked) { create(:confirmed_user) }
    let(:partner) { create(:confirmed_user) }
    let(:tutor) { create(:confirmed_user) }

    before do
      [marked, partner].each do |member|
        create(:lecture_membership, lecture: lecture, user: member)
        create(:tutorial_membership, tutorial: tutorial, user: member)
      end
      one = create(:assessment_participation, assessment: sheet.assessment,
                                              user: marked, status: :pending,
                                              submitted_at: 2.days.ago)
      create(:assessment_task_point, assessment_participation: one, task: task,
                                     points: 7.5, grader: tutor)
      one.update!(status: :reviewed, graded_at: 1.day.ago, grader: tutor,
                  points_total: 7.5)
      create(:assessment_participation, assessment: sheet.assessment,
                                        user: partner, status: :pending,
                                        submitted_at: 2.days.ago)
    end

    it "gives the partner the marked member's points and verdict" do
      Demo::SetupSupport.send(:align_team_marks!, sheet, [marked, partner])

      partners = sheet.assessment.assessment_participations.find_by(user: partner)
      expect(partners.task_points.pluck(:task_id, :points)).to eq([[task.id, 7.5]])
      expect(partners).to be_reviewed
      expect(partners.points_total).to eq(7.5)
    end

    # An excused member does not hand in that week, so the team that does
    # is the rest of it.
    it "keeps an excused member out of the week's team" do
      partners = sheet.assessment.assessment_participations.find_by(user: partner)
      partners.update!(submitted_at: nil)
      partners.update!(status: :exempt)

      expect(Demo::SetupSupport.send(:sits_out?, sheet, partner, tutorial)).to be(true)
      expect(Demo::SetupSupport.send(:sits_out?, sheet, marked, tutorial)).to be(false)
    end

    it "keeps a member the gradebook dropped out of it as well" do
      sheet.assessment.assessment_participations.find_by(user: partner).destroy!

      expect(Demo::SetupSupport.send(:sits_out?, sheet, partner, tutorial)).to be(true)
    end

    # The cross in the performance table is a participation without a stamp;
    # a hand-in for that person would put the stamp there.
    it "keeps a member the gradebook recorded as missing out of it" do
      sheet.assessment.assessment_participations.find_by(user: partner)
           .update!(submitted_at: nil)

      expect(Demo::SetupSupport.send(:sits_out?, sheet, partner, tutorial)).to be(true)
    end

    # The sheet was handed in where the participation says, before the move;
    # the new group gets no file for it.
    it "keeps a member whose sheet another group holds out of it" do
      elsewhere = create(:tutorial, lecture: lecture)
      sheet.assessment.assessment_participations.find_by(user: partner)
           .update!(tutorial: elsewhere)

      expect(Demo::SetupSupport.send(:sits_out?, sheet, partner, tutorial)).to be(true)
    end
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
