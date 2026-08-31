require "rails_helper"

RSpec.describe(Assessment::SubmissionsHub::Loader) do
  subject(:result) { described_class.new(lecture: lecture, user: user).call }

  let(:lecture) do
    create(:lecture, :released_for_all, submission_grace_period: 60)
  end
  let(:tutor) { create(:confirmed_user) }
  let(:user) { create(:confirmed_user) }

  # One group per lecture, made on first use: a submission has to hang on a
  # tutorial of its own lecture.
  def tutorial_for(some_lecture)
    @tutorials ||= {}
    @tutorials[some_lecture.id] ||= create(:tutorial, lecture: some_lecture)
  end

  def tutorial
    tutorial_for(lecture)
  end

  # Sheets are put together by hand rather than through one factory trait: every
  # state below is a different combination of assignment, participation and
  # submission, and naming that combination is the point of these examples. A
  # deadline in the past goes through the :expired trait, which is what gets it
  # past the validation that refuses one.
  def create_assignment(title: "Homework", deadline: 1.week.from_now,
                        max_points: [4, 4], in_lecture: lecture)
    assignment =
      if deadline.future?
        create(:assignment, lecture: in_lecture, title: title, deadline: deadline)
      else
        create(:assignment, :expired, lecture: in_lecture, title: title,
                                      expired_since: (Time.zone.now - deadline).seconds)
      end
    max_points.each do |points|
      create(:assessment_task, assessment: assignment.assessment,
                               max_points: points)
    end
    assignment
  end

  def participate(assignment, **attrs)
    create(:assessment_participation, assessment: assignment.assessment,
                                      user: user, **attrs)
  end

  # Points on every task and the status turned afterwards - a new task reopens
  # every reviewed participation of its assessment.
  def mark(assignment, points_per_task, grader: tutor)
    participation = participate(assignment, submitted_at: 3.days.ago)
    tasks_of(assignment).each_with_index do |task, index|
      create(:assessment_task_point, task: task, grader: grader,
                                     assessment_participation: participation,
                                     points: points_per_task[index])
    end
    participation.reload.tap do |reloaded|
      reloaded.update!(status: :reviewed, graded_at: 2.days.ago, grader: grader)
    end
  end

  # A row the tutor saved half typed: values on some tasks, the participation
  # still pending, which is where `update_status_if_all_scored!` leaves it.
  def mark_partially(assignment, points_per_task)
    participation = participate(assignment, submitted_at: 3.days.ago)
    tasks_of(assignment).each_with_index do |task, index|
      create(:assessment_task_point, task: task,
                                     assessment_participation: participation,
                                     points: points_per_task[index])
    end
    participation.reload
  end

  def tasks_of(assignment)
    assignment.assessment.tasks.order(:position).to_a
  end

  def hand_in(assignment, manuscript: true, correction: false, accepted: nil,
              handed_in_at: nil)
    traits = []
    traits << :with_manuscript if manuscript
    traits << :with_correction if correction
    submission = create(:submission, *traits,
                        assignment: assignment,
                        tutorial: tutorial_for(assignment.lecture),
                        accepted: accepted)
    submission.users << user
    submission.update!(last_modification_by_users_at: handed_in_at) if handed_in_at
    submission
  end

  def sheet_for(assignment)
    result.sheets.find { |sheet| sheet.assignment == assignment }
  end

  describe "the sheet list" do
    it "is empty for a lecture without assignments" do
      expect(result.sheets).to be_empty
    end

    it "carries every assignment of the lecture, newest deadline first" do
      old = create_assignment(title: "Homework 1", deadline: 3.weeks.ago)
      recent = create_assignment(title: "Homework 2", deadline: 1.week.ago)
      upcoming = create_assignment(title: "Homework 3")

      expect(result.sheets.map(&:assignment)).to eq([upcoming, recent, old])
    end

    it "leaves out assignments of another lecture" do
      other = create(:assignment, lecture: create(:lecture), title: "Elsewhere")

      expect(result.sheets.map(&:assignment)).not_to include(other)
    end

    it "carries the tasks of a sheet in their listed order" do
      assignment = create_assignment(max_points: [4, 6, 10])

      expect(sheet_for(assignment).tasks.map(&:max_points))
        .to eq(tasks_of(assignment).map(&:max_points))
    end

    it "reports the maximum points as the sum over the tasks" do
      assignment = create_assignment(max_points: [4, 6, 10])

      expect(sheet_for(assignment).max_points).to eq(20)
    end
  end

  describe "the reader's own points" do
    it "are the participation's total once the sheet is marked" do
      assignment = create_assignment(deadline: 1.week.ago, max_points: [4, 4])
      mark(assignment, [1.5, 2])

      expect(sheet_for(assignment).points).to eq(3.5)
    end

    it "are the points per task, indexed by task" do
      assignment = create_assignment(deadline: 1.week.ago, max_points: [4, 4])
      mark(assignment, [1.5, 2])

      first, second = tasks_of(assignment)
      sheet = sheet_for(assignment)
      expect([sheet.points_for(first), sheet.points_for(second)]).to eq([1.5, 2])
    end

    # One submission, two people, two numbers: the team hands in together and is
    # marked apart.
    it "are the reader's, not the team's" do
      assignment = create_assignment(deadline: 1.week.ago, max_points: [4, 4])
      partner = create(:confirmed_user)
      submission = hand_in(assignment, handed_in_at: 8.days.ago)
      submission.users << partner
      mark(assignment, [1.5, 2])
      partner_participation = create(:assessment_participation,
                                     assessment: assignment.assessment,
                                     user: partner, submitted_at: 3.days.ago)
      tasks_of(assignment).each do |task|
        create(:assessment_task_point, task: task, points: 4,
                                       assessment_participation: partner_participation)
      end

      expect(sheet_for(assignment).points).to eq(3.5)
      expect(partner_participation.reload.points_total).to eq(8)
    end

    it "are nil while nothing has been entered" do
      assignment = create_assignment
      participate(assignment, submitted_at: 1.hour.ago)

      expect(sheet_for(assignment).points).to be_nil
    end

    it "are what has been entered while the rest is still being typed" do
      assignment = create_assignment(deadline: 1.week.ago)
      mark_partially(assignment, [1.5, nil])

      expect(sheet_for(assignment).points).to eq(1.5)
    end

    it "are zero where the sheet counts as not handed in" do
      assignment = create_assignment(deadline: 3.weeks.ago)

      expect(sheet_for(assignment).points).to eq(0)
    end
  end

  describe "the files" do
    it "carries the reader's own submission" do
      assignment = create_assignment
      submission = hand_in(assignment)

      expect(sheet_for(assignment).submission).to eq(submission)
    end

    it "reaches both the manuscript and the correction" do
      assignment = create_assignment(deadline: 1.week.ago)
      hand_in(assignment, correction: true, handed_in_at: 8.days.ago)

      sheet = sheet_for(assignment)
      expect(sheet.submission.manuscript).to be_present
      expect(sheet.submission.correction).to be_present
    end

    it "leaves a submission of somebody else's team alone" do
      assignment = create_assignment
      create(:submission, :with_manuscript, assignment: assignment,
                                            tutorial: tutorial)

      expect(sheet_for(assignment).submission).to be_nil
    end

    it "names the team without the reader" do
      assignment = create_assignment
      partner = create(:confirmed_user)
      hand_in(assignment).users << partner

      sheet = sheet_for(assignment)
      expect(sheet.team).to contain_exactly(user, partner)
      expect(sheet.partners).to contain_exactly(partner)
    end
  end

  describe "the state of a row" do
    it "is :no_points for a sheet without a pointbook" do
      assignment = create(:assignment, :without_assessment, lecture: lecture,
                                                            title: "Blatt 4")

      expect(sheet_for(assignment).state).to eq(:no_points)
    end

    it "is :no_points for a pointbook that carries no points" do
      assignment = create_assignment(max_points: [])
      assignment.assessment.update!(requires_points: false)

      expect(sheet_for(assignment).state).to eq(:no_points)
    end

    it "is :exempt for a sheet the reader was let off" do
      assignment = create_assignment(deadline: 1.week.ago)
      participate(assignment, status: :exempt)

      expect(sheet_for(assignment).state).to eq(:exempt)
    end

    it "is :marked once a task carries a value" do
      assignment = create_assignment(deadline: 1.week.ago)
      mark(assignment, [1.5, 2])

      expect(sheet_for(assignment).state).to eq(:marked)
    end

    # Reviewed with nothing entered: the status was turned by hand, or every
    # field was left blank. Either way there is nothing to show.
    it "is :awaiting_marks when reviewed but nothing was entered" do
      assignment = create_assignment(deadline: 1.week.ago)
      mark(assignment, [nil, nil])

      expect(sheet_for(assignment).state).to eq(:awaiting_marks)
    end

    # Three problems typed, the fourth still open: the number is there, and it
    # must stay there while the tutor works through the rest.
    it "is :partially_marked while only some problems carry a value" do
      assignment = create_assignment(deadline: 1.week.ago)
      mark_partially(assignment, [1.5, nil])

      expect(sheet_for(assignment).state).to eq(:partially_marked)
    end

    it "is :rejected when the tutor did not let a late hand-in count" do
      assignment = create_assignment(deadline: 1.week.ago)
      participate(assignment, submitted_at: 6.days.ago)
      hand_in(assignment, accepted: false, handed_in_at: 6.days.ago)

      expect(sheet_for(assignment).state).to eq(:rejected)
    end

    it "is :absent for a sheet recorded as a no-show" do
      assignment = create_assignment(deadline: 1.week.ago)
      participate(assignment, status: :absent)

      expect(sheet_for(assignment).state).to eq(:absent)
    end

    it "is :correction_uploaded once a correction is there but no points are" do
      assignment = create_assignment(deadline: 1.week.ago)
      participate(assignment, submitted_at: 8.days.ago)
      hand_in(assignment, correction: true, handed_in_at: 8.days.ago)

      expect(sheet_for(assignment).state).to eq(:correction_uploaded)
    end

    it "is :awaiting_marks once the sheet is closed and nothing came back" do
      assignment = create_assignment(deadline: 1.week.ago)
      participate(assignment, submitted_at: 8.days.ago)
      hand_in(assignment, handed_in_at: 8.days.ago)

      expect(sheet_for(assignment).state).to eq(:awaiting_marks)
    end

    # The file is there and the gradebook has no record of it - the one state
    # that costs points without the reader having done anything wrong.
    it "is :not_recorded when the file is there but the gradebook is not" do
      assignment = create_assignment(deadline: 1.week.ago)
      hand_in(assignment, handed_in_at: 8.days.ago)

      expect(sheet_for(assignment).state).to eq(:not_recorded)
    end

    it "is :missed when nothing arrived by the deadline" do
      assignment = create_assignment(deadline: 1.week.ago)

      expect(sheet_for(assignment).state).to eq(:missed)
    end

    it "is :tutor_decides for a late hand-in nobody has ruled on" do
      assignment = create_assignment(deadline: 10.minutes.ago)
      hand_in(assignment)

      expect(sheet_for(assignment).state).to eq(:tutor_decides)
    end

    it "is :grace_period while the deadline has passed but the sheet has not" do
      assignment = create_assignment(deadline: 10.minutes.ago)

      expect(sheet_for(assignment).state).to eq(:grace_period)
    end

    it "is :handed_in while the sheet is open and a file is there" do
      assignment = create_assignment
      hand_in(assignment)

      expect(sheet_for(assignment).state).to eq(:handed_in)
    end

    it "is :nothing_handed_in while the sheet is open and nothing is there" do
      assignment = create_assignment

      expect(sheet_for(assignment).state).to eq(:nothing_handed_in)
    end
  end

  describe "who marked a sheet and when" do
    let(:assignment) { create_assignment(deadline: 1.week.ago) }

    it "reads the participation once it is stamped" do
      participation = mark(assignment, [1.5, 2])

      sheet = sheet_for(assignment)
      expect(sheet.marked_by).to eq(tutor)
      expect(sheet.marked_at).to be_within(1.second).of(participation.graded_at)
    end

    # Nothing in the app stamps the participation yet, so the task points are
    # what actually carries the marking.
    it "falls back to the task points while it is not" do
      participation = mark(assignment, [1.5, 2])
      participation.update!(graded_at: nil, grader: nil)

      sheet = sheet_for(assignment)
      expect(sheet.marked_by).to eq(tutor)
      expect(sheet.marked_at)
        .to be_within(1.second).of(participation.task_points.maximum(:updated_at))
    end

    it "is nil for a sheet with no participation at all" do
      expect(sheet_for(assignment).marked_at).to be_nil
      expect(sheet_for(assignment).marked_by).to be_nil
    end
  end

  describe "#open_sheets" do
    it "is empty when every deadline has passed" do
      create_assignment(deadline: 1.week.ago)

      expect(result.open_sheets).to be_empty
    end

    # A sheet weeks away is still a sheet you may hand in early, so it needs its
    # card; the soonest one leads.
    it "carries every sheet that can still be handed in, soonest first" do
      create_assignment(title: "Homework 1", deadline: 1.week.ago)
      later = create_assignment(title: "Homework 3", deadline: 9.days.from_now)
      next_up = create_assignment(title: "Homework 2", deadline: 2.days.from_now)

      expect(result.open_sheets.map(&:assignment)).to eq([next_up, later])
    end

    it "carries a sheet still inside its grace period" do
      assignment = create_assignment(deadline: 10.minutes.ago)

      expect(result.open_sheets.map(&:assignment)).to eq([assignment])
    end
  end

  describe "#due" do
    it "is empty when every deadline has passed" do
      create_assignment(deadline: 1.week.ago)

      expect(result.due).to be_empty
    end

    # The card has the most to say during the grace period ("15 minutes left"),
    # so a sheet whose deadline has just passed is still the one that is due -
    # which is where `Lecture#current_assignments` and this part company.
    it "carries a sheet still inside its grace period" do
      assignment = create_assignment(deadline: 10.minutes.ago)

      expect(result.due.map(&:assignment)).to eq([assignment])
    end

    # `open` holds the later ones as well; `due` is only what the head leads with.
    it "is the sheet with the earliest deadline still ahead" do
      create_assignment(title: "Homework 1", deadline: 1.week.ago)
      next_up = create_assignment(title: "Homework 2", deadline: 2.days.from_now)
      create_assignment(title: "Homework 3", deadline: 9.days.from_now)

      expect(result.due.map(&:assignment)).to eq([next_up])
    end

    # A lecture may set two sheets for the same date; the page shows a card each.
    it "carries every sheet sharing that deadline" do
      deadline = 2.days.from_now.change(usec: 0)
      first = create_assignment(title: "Homework 2a", deadline: deadline)
      second = create_assignment(title: "Homework 2b", deadline: deadline)

      expect(result.due.map(&:assignment)).to contain_exactly(first, second)
    end
  end

  # What is still there to be won. The record cannot say this: it counts only
  # sheets that are handed in and waiting, so a sheet nobody has handed in yet
  # would look, from the record alone, like a sheet already lost.
  describe "the points still open" do
    it "counts a sheet that is open and untouched" do
      create_assignment(title: "Homework 1", max_points: [4, 6])

      expect(result.standing.points_still_open).to eq(10)
    end

    it "counts a sheet that is handed in and waiting" do
      assignment = create_assignment(title: "Homework 1", deadline: 1.week.ago,
                                     max_points: [4, 6])
      participate(assignment, submitted_at: 8.days.ago)

      expect(result.standing.points_still_open).to eq(10)
    end

    it "does not count a sheet that has been marked" do
      assignment = create_assignment(title: "Homework 1", deadline: 1.week.ago,
                                     max_points: [4, 6])
      mark(assignment, [1.5, 2])

      expect(result.standing.points_still_open).to eq(0)
    end

    it "does not count a sheet that counts as nothing" do
      create_assignment(title: "Homework 1", deadline: 1.week.ago,
                        max_points: [4, 6])

      expect(result.standing.points_still_open).to eq(0)
    end

    it "does not count a sheet the reader was let off" do
      assignment = create_assignment(title: "Homework 1", deadline: 1.week.ago,
                                     max_points: [4, 6])
      participate(assignment, status: :exempt)

      expect(result.standing.points_still_open).to eq(0)
    end

    # A half-marked sheet keeps its whole worth: its points are not in the total
    # either, because the record sums only what is finished.
    it "counts a sheet that is only half marked" do
      assignment = create_assignment(title: "Homework 1", deadline: 1.week.ago,
                                     max_points: [4, 6])
      participation = participate(assignment, submitted_at: 8.days.ago)
      create(:assessment_task_point, task: tasks_of(assignment).first,
                                     assessment_participation: participation,
                                     points: 1.5)

      expect(sheet_for(assignment).state).to eq(:partially_marked)
      expect(result.standing.points_still_open).to eq(10)
    end
  end

  describe "#latest_marked" do
    it "is nil while nothing has come back" do
      create_assignment(deadline: 1.week.ago)

      expect(result.latest_marked).to be_nil
    end

    it "is the sheet marked most recently, not the newest one" do
      newest = create_assignment(title: "Homework 2", deadline: 1.week.ago)
      older = create_assignment(title: "Homework 1", deadline: 3.weeks.ago)
      mark(newest, [1, 1]).update!(graded_at: 5.days.ago)
      mark(older, [2, 2]).update!(graded_at: 1.day.ago)

      expect(result.latest_marked.assignment).to eq(older)
    end
  end

  describe "the standing" do
    it "carries the reader's materialized record" do
      record = create(:student_performance_record, lecture: lecture, user: user,
                                                   points_total_materialized: 32.5,
                                                   points_max_materialized: 176,
                                                   points_max_pending_materialized: 16,
                                                   percentage_materialized: 18.47)

      standing = result.standing
      expect(standing.record).to eq(record)
      expect(standing.points_total).to eq(32.5)
      expect(standing.points_max).to eq(176)
      expect(standing.points_pending).to eq(16)
      expect(standing.percentage).to eq(18.47)
    end

    it "leaves the record nil for somebody who has none" do
      create(:student_performance_record, lecture: lecture,
                                          user: create(:confirmed_user))

      expect(result.standing.record).to be_nil
    end

    it "says whether the lecture runs exam admission at all" do
      lecture.update!(uses_exam_eligibility: false)

      expect(result.standing.uses_exam_eligibility).to be(false)
    end

    it "carries no rule when the lecture has none" do
      expect(result.standing.rule).to be_nil
      expect(result.standing.required_achievements).to be_empty
    end

    it "carries the active rule and its required achievements" do
      achievement = create(:achievement, lecture: lecture,
                                         title: "Blackboard Talk")
      rule = create(:student_performance_rule, :active, lecture: lecture)
      rule.required_achievements << achievement
      create(:student_performance_rule, lecture: lecture, active: false)

      expect(result.standing.rule).to eq(rule)
      expect(result.standing.required_achievements).to eq([achievement])
    end

    describe "the standing of one achievement" do
      let(:achievement) { create(:achievement, lecture: lecture) }

      def standing_with(met: [], ungraded: [])
        create(:student_performance_record, lecture: lecture, user: user,
                                            achievements_met_ids: met,
                                            achievements_ungraded_ids: ungraded)
        result.standing
      end

      it "is :met when the record lists it as met" do
        expect(standing_with(met: [achievement.id])
                 .achievement_status(achievement)).to eq(:met)
      end

      it "is :ungraded when the record lists it as not graded yet" do
        expect(standing_with(ungraded: [achievement.id])
                 .achievement_status(achievement)).to eq(:ungraded)
      end

      it "is :not_met when the record lists it in neither" do
        expect(standing_with.achievement_status(achievement)).to eq(:not_met)
      end

      it "is :unknown without a record to read" do
        expect(result.standing.achievement_status(achievement)).to eq(:unknown)
      end
    end

    # The record knows met and not-graded-yet, never the value behind either.
    it "carries the value recorded for an achievement" do
      achievement = create(:achievement, :percentage, lecture: lecture)
      create(:assessment_participation, assessment: achievement.assessment,
                                        user: user, grade_text: "67.3")

      expect(result.standing.achievement_value(achievement)).to eq("67.3")
    end

    it "carries no value for an achievement nobody has recorded" do
      achievement = create(:achievement, lecture: lecture)
      create(:assessment_participation, assessment: achievement.assessment,
                                        user: user, grade_text: "")

      expect(result.standing.achievement_value(achievement)).to be_nil
    end

    it "leaves another student's value alone" do
      achievement = create(:achievement, lecture: lecture)
      create(:assessment_participation, assessment: achievement.assessment,
                                        user: create(:confirmed_user),
                                        grade_text: "pass")

      expect(result.standing.achievement_value(achievement)).to be_nil
    end
  end

  # The one assurance that keeps a later `includes` from being dropped by
  # somebody who cannot see what it was for.
  describe "the number of queries" do
    def count_queries
      count = 0
      subscription = ActiveSupport::Notifications
                     .subscribe("sql.active_record") do |*, payload|
        count += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION|CACHE/)
      end
      yield
      count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    # Reading a result means touching every row of it, which is where an N+1
    # would show up.
    def read_everything(loaded)
      loaded.sheets.each do |sheet|
        sheet.state
        sheet.points
        sheet.max_points
        sheet.marked_at
        sheet.marked_by
        sheet.partners
        sheet.tasks.each { |task| sheet.points_for(task) }
      end
      loaded.due
      loaded.latest_marked
      standing = loaded.standing
      standing.required_achievements.each do |achievement|
        standing.achievement_status(achievement)
        standing.achievement_value(achievement)
      end
    end

    # A lecture of its own per measurement, so the second does not read the
    # sheets of the first. Every sheet is fully furnished - marked, handed in,
    # corrected - because an association nobody touches is one no count catches.
    def scenario(sheet_count)
      built = create(:lecture, :released_for_all, submission_grace_period: 60)
      sheet_count.times do |index|
        assignment = create_assignment(title: "Homework #{index + 1}",
                                       deadline: (sheet_count - index).weeks.ago,
                                       in_lecture: built)
        hand_in(assignment, correction: true,
                            handed_in_at: (sheet_count - index).weeks.ago - 1.day)
        mark(assignment, [1.5, 2])
      end
      achievement = create(:achievement, lecture: built)
      rule = create(:student_performance_rule, :active, lecture: built)
      rule.required_achievements << achievement
      create(:assessment_participation, assessment: achievement.assessment,
                                        user: user, grade_text: "pass")
      create(:student_performance_record, lecture: built, user: user,
                                          achievements_met_ids: [achievement.id])
      built
    end

    def queries_for(sheet_count)
      built = scenario(sheet_count)

      count_queries { read_everything(described_class.new(lecture: built, user: user).call) }
    end

    it "does not grow with the number of sheets" do
      expect(queries_for(20)).to eq(queries_for(2))
    end

    it "stays in the low teens" do
      expect(queries_for(12)).to be <= 15
    end
  end
end
