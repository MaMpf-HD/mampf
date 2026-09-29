require "rails_helper"

RSpec.describe(Assessment::Statistics) do
  describe ".figures" do
    it "takes the middle of an even count as the mean of the two middle values" do
      figures = described_class.figures([1, 4, 2, 3])

      expect(figures).to have_attributes(number: 4, mean: 2.5, median: 2.5)
    end

    it "has nothing to say about no values" do
      expect(described_class.figures([])).to have_attributes(number: 0, mean: nil)
    end
  end

  context "with a marked sheet" do
    let(:assessment) { create(:assessment, :for_expired_assignment, :with_points) }
    let!(:first_task) { create(:assessment_task, assessment: assessment, max_points: 4) }
    let!(:second_task) { create(:assessment_task, assessment: assessment, max_points: 6) }
    let(:statistics) { described_class.new(assessment.reload) }

    def mark(first, second, **user_attributes)
      tutorial = user_attributes.delete(:tutorial)
      row = create(:assessment_participation,
                   assessment: assessment, tutorial: tutorial, submitted_at: 2.days.ago,
                   user: create(:confirmed_user, **user_attributes))
      [[first_task, first], [second_task, second]].each do |task, points|
        create(:assessment_task_point, task: task, assessment_participation: row, points: points)
      end
      row.reload.update!(status: :reviewed, graded_at: 1.day.ago)
      row
    end

    it "gives each task its mean, full marks and zero points" do
      mark(4, 0)
      mark(2, 6)
      mark(4, 3)

      first, second = statistics.task_rows

      expect(first.figures.mean).to be_within(0.01).of(10.0 / 3)
      expect(first.full_share).to be_within(0.01).of(2.0 / 3)
      expect(first.zero_share).to eq(0)
      expect(second.figures.mean).to eq(3.0)
      expect(second.zero_share).to be_within(0.01).of(1.0 / 3)
    end

    it "leaves full marks and zero points empty for a task worth no points" do
      first_task.update!(max_points: 0)
      mark(0, 6)

      expect(statistics.task_rows.first).to have_attributes(full_share: nil, zero_share: nil)
    end

    it "leaves rows still being marked out of the figures but counts them" do
      mark(4, 6)
      half = create(:assessment_participation, assessment: assessment,
                                               submitted_at: 2.days.ago)
      create(:assessment_task_point, task: first_task, assessment_participation: half,
                                     points: 1)

      expect(statistics.counts).to include(total: 2, marked: 1)
      expect(statistics.task_rows.first.figures.number).to eq(1)
    end

    it "counts absent and exempt rows but leaves them out of the points" do
      program = create(:program, degree: "msc")
      mark(4, 6, program: program)
      [:absent, :exempt].each do |status|
        create(:assessment_participation, status, assessment: assessment,
                                                  user: create(:confirmed_user, program: program))
      end

      expect(statistics.counts).to include(total: 3, marked: 1, absent: 1, exempt: 1)
      expect(statistics.task_rows.map { |row| row.figures.number }).to eq([1, 1])
      expect(statistics.program_rows.sole).to have_attributes(people: 3)
      expect(statistics.program_rows.sole.figures).to have_attributes(number: 1, mean: 10.0)
    end

    it "groups the people by program, the ones without one last" do
      program = create(:program, degree: "msc")
      mark(4, 6, program: program)
      mark(2, 2, program: program)
      mark(0, 0)

      rows = statistics.program_rows

      expect(rows.map(&:label)).to eq([program.name_with_subject, nil])
      expect(rows.first).to have_attributes(people: 2)
      expect(rows.first.figures.mean).to eq(7.0)
    end

    it "groups by program only where somebody gave one" do
      mark(4, 6)

      expect(statistics.program_rows).to be_empty
    end

    it "groups by tutorial only where somebody sits in one" do
      mark(4, 6)
      expect(statistics.tutorial_rows).to be_empty

      tutorial = create(:tutorial, lecture: assessment.lecture, title: "Tuesday")
      mark(2, 2, tutorial: tutorial)

      expect(described_class.new(assessment).tutorial_rows.map(&:label))
        .to eq(["Tuesday", nil])
    end
  end

  context "with an exam's grades" do
    let(:assessment) { create(:assessment, :for_exam, :with_points) }

    it "gives the mean grade, how many passed and how the grades spread" do
      [1.3, 5.0, 2.0].each do |grade|
        create(:assessment_participation, :reviewed, assessment: assessment,
                                                     grade_numeric: grade)
      end

      statistics = described_class.new(assessment)

      expect(statistics.grades.mean).to be_within(0.01).of(8.3 / 3)
      expect(statistics.grades.pass_share).to be_within(0.01).of(2.0 / 3)
      expect(statistics.grade_distribution.to_h).to include(1.3 => 1, 2.0 => 1, 5.0 => 1,
                                                            1.0 => 0)
    end

    # The grade scheme writes 5.0 for the absent; counted in, it would pull the
    # pass share of those who wrote down next to point figures without them.
    it "leaves the absent out of the grades, their 5.0 included" do
      create(:assessment_participation, :reviewed, assessment: assessment, grade_numeric: 2.0)
      create(:assessment_participation, :reviewed, assessment: assessment, grade_numeric: 5.0)
      create(:assessment_participation, assessment: assessment, status: :absent,
                                        grade_numeric: 5.0)

      statistics = described_class.new(assessment)

      expect(statistics.grades).to have_attributes(number: 2, pass_share: 0.5)
      expect(statistics.grade_distribution.to_h[5.0]).to eq(1)
      expect(statistics.counts[:absent]).to eq(1)
    end
  end
end
