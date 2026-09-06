require "rails_helper"

RSpec.describe(StudentPerformance::DuePoints) do
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

  describe "#max_for" do
    it "drops a sheet the student was excused from" do
      excused = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, :exempt,
                        assessment: excused, user: student)

      expect(due_points.max_for(student.id)).to eq(16)
    end

    it "asks everybody else for the full amount" do
      excused = sheet(deadline: 3.days.ago, points: 20)
      sheet(deadline: 2.days.ago, points: 16)
      FactoryBot.create(:assessment_participation, :exempt,
                        assessment: excused, user: student)
      other = FactoryBot.create(:confirmed_user)

      expect(due_points.max_for(other.id)).to eq(36)
    end
  end

  describe "#percentage_for" do
    it "measures against what was due, not against every sheet on record" do
      sheet(deadline: 2.days.ago, points: 20)
      sheet(deadline: 3.days.from_now, points: 20)
      record = record_for(student, total: 20, max: 40)

      expect(due_points.percentage_for(record)).to eq(100)
    end

    it "refuses to divide by a term that has not asked for anything yet" do
      sheet(deadline: 3.days.from_now, points: 20)
      record = record_for(student, total: 0, max: 20)

      expect(due_points.percentage_for(record)).to be_nil
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

    # The early hand-in is already in `points_max_pending_materialized`;
    # counting it here as well would let one sheet carry a student twice.
    it "drops a sheet to come that the student has already handed in" do
      early = sheet(deadline: 3.days.from_now, points: 16)
      sheet(deadline: 4.days.from_now, points: 20)
      FactoryBot.create(:assessment_participation, :submitted,
                        assessment: early, user: student)

      expect(due_points.not_yet_due_for(student.id)).to eq(20)
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
