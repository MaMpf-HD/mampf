require "rails_helper"

RSpec.describe(StatisticsTabComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  let(:assessment) { create(:assessment, :for_expired_assignment, :with_points) }
  let!(:task) { create(:assessment_task, assessment: assessment, max_points: 10) }

  def render_tab
    render_inline(described_class.new(assessment: assessment.reload,
                                      lecture: assessment.lecture))
  end

  def mark(points, program: nil)
    row = create(:assessment_participation, assessment: assessment, submitted_at: 2.days.ago,
                                            user: create(:confirmed_user, program: program))
    create(:assessment_task_point, task: task, assessment_participation: row, points: points)
    row.reload.update!(status: :reviewed, graded_at: 1.day.ago)
  end

  it "says so while nothing has been marked in full" do
    create(:assessment_participation, assessment: assessment)

    expect(render_tab.text.squish).to include("0 of 1 marked in full",
                                              "Nothing has been marked in full yet.")
  end

  it "shows the tasks and the programs once something is marked" do
    program = create(:program, degree: "msc")
    mark(8, program: program)
    mark(4)

    page = render_tab
    tables = page.css("section").index_by { |section| section.at_css("h6")&.text&.squish }

    expect(tables["Tasks"].at_css("tbody tr").text.squish).to include("Task 1", "10", "6")
    programs = tables["By program"].css("tbody th").map { |cell| cell.text.squish }
    expect(programs).to eq([program.name_with_subject, "No program given"])
    expect(page.text).not_to include("Coming soon")
  end

  context "with an exam's grades" do
    let(:assessment) { create(:assessment, :for_exam, :with_points) }

    it "adds the mean grade, how many passed and the spread of the grades" do
      [1.3, 5.0].each do |value|
        create(:assessment_participation, :reviewed, assessment: assessment,
                                                     grade_numeric: value)
      end

      page = render_tab

      expect(page.text.squish).to include("Mean grade 3.2", "Passed 50%")
      grades = page.css("section").find { |section| section.at_css("h6")&.text&.squish == "Grades" }
      expect(grades.css("tbody th").map { |cell| cell.text.squish }).to include("1.0", "4.0", "5.0")
    end
  end
end
