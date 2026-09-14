require "rails_helper"

RSpec.describe(StudentPerformance::DuePoints) do
  include ActiveSupport::Testing::TimeHelpers

  let(:lecture) { FactoryBot.create(:lecture, :released_for_all) }
  let(:student) { FactoryBot.create(:confirmed_user) }
  let(:due_points) { described_class.new(lecture: lecture) }

  # A deadline in the past is refused on the way in, exactly as the demo data
  # and the assignment factory work around it.
  def sheet(deadline:, points:)
    assignment = FactoryBot.create(:assignment, lecture: lecture)
    # rubocop:disable Rails/SkipsModelValidations
    assignment.update_column(:deadline, deadline)
    # rubocop:enable Rails/SkipsModelValidations
    assessment = assignment.assessment
    FactoryBot.create(:assessment_task, assessment: assessment,
                                        max_points: points)
    assessment.reload
  end

  def record_for(user, total:, max:)
    FactoryBot.create(:student_performance_record,
                      lecture: lecture, user: user,
                      points_total_materialized: total,
                      points_max_materialized: max)
  end

  describe "#total" do
    it "counts a sheet whose deadline has passed" do
      sheet(deadline: 2.days.ago, points: 20)

      expect(due_points.total).to eq(20)
    end

    it "leaves out a sheet nobody could hand in yet" do
      sheet(deadline: 2.days.ago, points: 20)
      sheet(deadline: 3.days.from_now, points: 16)

      expect(due_points.total).to eq(20)
    end

    it "waits for the grace period to run out" do
      lecture.update!(submission_grace_period: 60)
      sheet(deadline: 30.minutes.ago, points: 20)

      expect(due_points.total).to be_zero
    end
  end

  describe "#due?" do
    it "separates the sheets that were asked for from the ones to come" do
      past = sheet(deadline: 2.days.ago, points: 20)
      future = sheet(deadline: 3.days.from_now, points: 16)

      expect(due_points.due?(past.id)).to be(true)
      expect(due_points.due?(future.id)).to be(false)
    end
  end

  describe "#marked_max_for" do
    it "drops a sheet the student was excused from" do
      excused = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, :exempt,
                        assessment: excused, user: student)

      expect(due_points.marked_max_for(student.id)).to eq(16)
    end

    it "asks everybody else for the full amount" do
      excused = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, :exempt,
                        assessment: excused, user: student)
      other = FactoryBot.create(:confirmed_user)

      expect(due_points.marked_max_for(other.id)).to eq(36)
    end

    # A sheet in the tutor's queue is neither earned nor lost. Counted in, it
    # would put his backlog on her account; her figure would fall the day a
    # deadline passed and climb back when he got round to it.
    it "drops a sheet that was handed in and is waiting to be marked" do
      waiting = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, assessment: waiting,
                                                   user: student,
                                                   submitted_at: 4.days.ago)

      expect(due_points.marked_max_for(student.id)).to eq(16)
    end

    # Missed is not waiting: nothing will come of it, and a zero out of a base
    # that does not hold it would read as full marks.
    it "keeps a sheet nobody handed in" do
      missed = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, assessment: missed,
                                                   user: student,
                                                   submitted_at: nil)

      expect(due_points.marked_max_for(student.id)).to eq(36)
    end

    # A deadline may be moved forward at any time, and nothing forbids it once
    # marking has begun. The points stay in the total either way, so the sheet
    # has to stay in the base - otherwise 20 of 20 reads as 200 %.
    it "keeps a sheet that was marked before its deadline was moved forward" do
      extended = sheet(deadline: 3.days.ago, points: 20)
      FactoryBot.create(:assessment_participation, assessment: extended,
                                                   user: student,
                                                   submitted_at: 4.days.ago,
                                                   status: :reviewed)
      extended.assessable.update!(deadline: 5.days.from_now)

      expect(due_points.marked_max_for(student.id)).to eq(20)
    end

    it "keeps a sheet that has come back" do
      marked = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, assessment: marked,
                                                   user: student,
                                                   submitted_at: 4.days.ago,
                                                   status: :reviewed)

      expect(due_points.marked_max_for(student.id)).to eq(36)
    end
  end

  describe "#marked_percentage_for" do
    it "measures against what was due, not against every sheet that exists" do
      sheet(deadline: 2.days.ago, points: 20)
      sheet(deadline: 3.days.from_now, points: 20)
      record = record_for(student, total: 20, max: 40)

      expect(due_points.marked_percentage_for(record)).to eq(100)
    end

    # The whole point of the basis: a flawless student does not drop below her
    # threshold because a tutor is behind.
    it "does not fall while a sheet sits in the tutor's queue" do
      sheet(deadline: 2.days.ago, points: 20)
      waiting = sheet(deadline: 2.days.ago, points: 20)
      FactoryBot.create(:assessment_participation, assessment: waiting,
                                                   user: student,
                                                   submitted_at: 3.days.ago)
      record = record_for(student, total: 20, max: 40)

      expect(due_points.marked_percentage_for(record)).to eq(100)
    end

    it "refuses to divide by a term that has not asked for anything yet" do
      sheet(deadline: 3.days.from_now, points: 20)
      record = record_for(student, total: 0, max: 20)

      expect(due_points.marked_percentage_for(record)).to be_nil
    end
  end

  # The reasons on the certification page say how many sheets they are about,
  # and the points beside them what those are worth. Both out of the same set.
  describe "#marked_percentage_for and a deadline that moved" do
    it "does not read full marks as more than everything" do
      extended = sheet(deadline: 3.days.ago, points: 20)
      FactoryBot.create(:assessment_participation, assessment: extended,
                                                   user: student,
                                                   submitted_at: 4.days.ago,
                                                   status: :reviewed)
      extended.assessable.update!(deadline: 5.days.from_now)
      record = record_for(student, total: 20, max: 20)

      expect(due_points.marked_percentage_for(record)).to eq(100)
    end
  end

  describe "#not_yet_due_count_for" do
    it "counts the sheets still to come" do
      sheet(deadline: 2.days.ago, points: 20)
      sheet(deadline: 3.days.from_now, points: 16)
      sheet(deadline: 5.days.from_now, points: 10)

      expect(due_points.not_yet_due_count_for(student.id)).to eq(2)
    end

    # The early hand-in can still be withdrawn until its deadline; the sheet
    # is to come like any other.
    it "leaves out one she was let off, and keeps one she handed in early" do
      excused = sheet(deadline: 3.days.from_now, points: 16)
      early = sheet(deadline: 5.days.from_now, points: 10)
      sheet(deadline: 7.days.from_now, points: 8)
      FactoryBot.create(:assessment_participation, :exempt,
                        assessment: excused, user: student)
      FactoryBot.create(:assessment_participation, assessment: early,
                                                   user: student,
                                                   submitted_at: 1.day.ago)

      expect(due_points.not_yet_due_count_for(student.id)).to eq(2)
    end
  end

  # With a tutor means: handed in, due, not marked. Before the deadline nobody
  # can mark anything, so an early hand-in is not waiting on anyone.
  describe "#pending_count_for and #pending_points_for" do
    it "counts what is due and waiting to be marked, and only that" do
      due = sheet(deadline: 2.days.ago, points: 20)
      coming = sheet(deadline: 3.days.from_now, points: 16)
      [due, coming].each do |assessment|
        FactoryBot.create(:assessment_participation, assessment: assessment,
                                                     user: student,
                                                     submitted_at: 1.day.ago)
      end

      expect(due_points.pending_count_for(student.id)).to eq(1)
      expect(due_points.pending_points_for(student.id)).to eq(20)
    end

    # Nothing is written when a deadline passes; the count has to move on its
    # own, which is why it is read off the clock rather than stored.
    it "starts counting the moment the grace period runs out" do
      lecture.update!(submission_grace_period: 60)
      sheet_id = sheet(deadline: 10.minutes.ago, points: 20).id
      FactoryBot.create(:assessment_participation, assessment_id: sheet_id,
                                                   user: student,
                                                   submitted_at: 1.day.ago)

      expect(due_points.pending_count_for(student.id)).to be_zero
      expect(due_points.not_yet_due_count_for(student.id)).to eq(1)

      travel_to(2.hours.from_now) do
        later = described_class.new(lecture: lecture)
        expect(later.pending_count_for(student.id)).to eq(1)
        expect(later.not_yet_due_count_for(student.id)).to be_zero
      end
    end

    # A deadline extended after the hand-in makes the hand-in provisional
    # again: the sheet goes back to the ones still to come.
    it "lets go of a hand-in whose deadline was extended" do
      assessment = sheet(deadline: 2.days.ago, points: 20)
      FactoryBot.create(:assessment_participation, assessment: assessment,
                                                   user: student,
                                                   submitted_at: 3.days.ago)
      expect(due_points.pending_points_for(student.id)).to eq(20)

      # rubocop:disable Rails/SkipsModelValidations
      assessment.assessable.update_column(:deadline, 3.days.from_now)
      # rubocop:enable Rails/SkipsModelValidations
      extended = described_class.new(lecture: lecture)

      expect(extended.pending_points_for(student.id)).to be_zero
      expect(extended.not_yet_due_for(student.id)).to eq(20)
    end

    it "does not count one that has come back" do
      marked = sheet(deadline: 2.days.ago, points: 20)
      FactoryBot.create(:assessment_participation, assessment: marked,
                                                   user: student,
                                                   submitted_at: 3.days.ago,
                                                   status: :reviewed)

      expect(due_points.pending_count_for(student.id)).to be_zero
    end

    it "does not count a sheet nobody handed in" do
      missed = sheet(deadline: 2.days.ago, points: 20)
      FactoryBot.create(:assessment_participation, assessment: missed,
                                                   user: student,
                                                   submitted_at: nil)

      expect(due_points.pending_count_for(student.id)).to be_zero
    end
  end

  # The same sheet must not be counted twice: its points are in the total, so
  # they are not also still to be had. Counted again, a threshold nobody can
  # reach any more would look reachable.
  describe "#not_yet_due_for and a deadline that moved" do
    it "does not offer marked points as still to be had" do
      extended = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 5.days.from_now, points: 16)
      FactoryBot.create(:assessment_participation, assessment: extended,
                                                   user: student,
                                                   submitted_at: 4.days.ago,
                                                   status: :reviewed)
      extended.assessable.update!(deadline: 5.days.from_now)

      expect(due_points.not_yet_due_for(student.id)).to eq(16)
      expect(due_points.not_yet_due_count_for(student.id)).to eq(1)
    end
  end

  describe "#not_yet_due_for" do
    it "names the sheets still to come" do
      sheet(deadline: 2.days.ago, points: 20)
      sheet(deadline: 3.days.from_now, points: 16)

      expect(due_points.not_yet_due_for(student.id)).to eq(16)
    end

    it "is nothing once every sheet is due" do
      sheet(deadline: 2.days.ago, points: 20)

      expect(due_points.not_yet_due_for(student.id)).to be_zero
    end

    it "drops a sheet to come that the student is already excused from" do
      excused = sheet(deadline: 3.days.from_now, points: 16)
      sheet(deadline: 4.days.from_now, points: 20)
      FactoryBot.create(:assessment_participation, :exempt,
                        assessment: excused, user: student)

      expect(due_points.not_yet_due_for(student.id)).to eq(20)
    end

    it "keeps a sheet to come that the student has already handed in" do
      early = sheet(deadline: 3.days.from_now, points: 16)
      sheet(deadline: 4.days.from_now, points: 20)
      FactoryBot.create(:assessment_participation, :submitted,
                        assessment: early, user: student)

      expect(due_points.not_yet_due_for(student.id)).to eq(36)
      expect(due_points.pending_points_for(student.id)).to be_zero
    end

    it "keeps a sheet to come that nobody has handed in" do
      sheet(deadline: 3.days.from_now, points: 16)
      FactoryBot.create(:assessment_participation, :pending,
                        assessment: sheet(deadline: 4.days.from_now,
                                          points: 20),
                        user: student)

      expect(due_points.not_yet_due_for(student.id)).to eq(36)
    end
  end
end
