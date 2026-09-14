require "rails_helper"

RSpec.describe(ExamGradingTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let!(:assessment) { create(:assessment, requires_points: true, assessable: exam) }
  let!(:task) { create(:assessment_task, assessment: assessment, max_points: 10) }
  let(:candidate) { create(:confirmed_user, name: "Ada") }

  before do
    create(:exam_roster_entry, exam: exam, user: candidate)
    allow(vc_test_controller).to receive(:current_user).and_return(teacher)
  end

  def component
    described_class.new(exam: exam.reload)
  end

  it "shares the candidates with the points table" do
    expect(component.rows.map(&:user)).to eq([candidate])
  end

  it "is the exam's grading table" do
    expect(component.layout.columns).to eq([:team, :status_compact, :total, :grade, :save])
  end

  # The status icon is where a reader learns who graded and when.
  it "tells who graded and when on the status icon" do
    participation = component.rows.first
    participation.update!(status: :reviewed, grade_numeric: 2.0, grader: teacher,
                          graded_at: 1.hour.ago, submitted_at: nil)

    icon = render_inline(component).css("td.status-compact-col [role=img]").first

    expect(icon["title"]).to include(I18n.t("student_performance.records.columns.reviewed"))
    expect(icon["title"]).to include(teacher.tutorial_name)
  end

  # A note is written for an exemption, in its dialog; the row has no field for one.
  it "draws a grade select and the exemption dialog, but no note field" do
    page = render_inline(component)

    expect(page.css("select[name=grade]").size).to eq(1)
    expect(page.css("td.note-col")).to be_empty
    expect(page.css("[data-controller=exempt-modal] textarea")).to be_present
    expect(page.css("tr[id^=grading-participation-row-]").size).to eq(1)
  end

  # A scheme saved but not applied shows what it would give; the field keeps
  # what the lecturer entered.
  describe "with a draft scheme" do
    let!(:draft) { create(:assessment_grade_scheme, assessment: assessment) }
    let(:proposed) { Assessment::GradeSchemeApplier.new(draft).proposed_grade_map[candidate.id] }

    before do
      participation = component.rows.first
      participation.update!(status: :reviewed, points_total: 10, submitted_at: nil)
      create(:assessment_task_point, task: task, assessment_participation: participation,
                                     points: 10)
    end

    it "shows the proposed grade beside a row that has none yet" do
      expect(render_inline(component).css("td.grade-col .badge").text.strip).to eq(proposed.to_s)
    end

    it "shows nothing beside a row whose grade already is the proposal" do
      component.rows.first.update!(grade_numeric: proposed)

      expect(render_inline(component).css("td.grade-col .badge")).to be_empty
    end

    # Once applied, the scheme's answer for today's points stays beside a
    # grade it no longer matches: nothing recomputes an applied grade.
    it "keeps showing what the applied scheme would give where the grade differs" do
      draft.update!(applied_at: Time.current, applied_by: teacher)
      component.rows.first.update!(grade_numeric: 1.0)

      badge = render_inline(component).css("td.grade-col .badge").first
      expect(badge.text.strip).to eq(proposed.to_s)
      expect(badge["title"]).to eq(I18n.t("assessment.grading_exam.scheme_now_gives"))
    end
  end

  describe "points changed after grading" do
    let(:participation) { component.rows.first }

    before do
      participation.update!(status: :reviewed, grade_numeric: 2.0, grader: teacher,
                            graded_at: 1.hour.ago, submitted_at: nil)
    end

    it "marks the row, counts it in the summary and says so above the table" do
      create(:assessment_task_point, task: task, assessment_participation: participation, points: 3)

      page = render_inline(component)

      expect(page.css("td.grade-col i.bi-exclamation-triangle-fill")).to be_present
      expect(page.css("p#grading-summary").text)
        .to include(I18n.t("assessment.grading_exam.summary_points_changed", count: 1))
      expect(page.css(".alert-warning").text)
        .to include(I18n.t("assessment.grading_exam.points_changed_alert", count: 1))
      expect(page.css("tr[data-status-filter-flags~=points_changed]").size).to eq(1)
      options = page.css("select[data-status-filter-target=status] option").pluck("value")
      expect(options).to include("flag:points_changed")
    end

    it "leaves a row alone whose points are older than its grade" do
      Timecop.travel(2.hours.ago) do
        create(:assessment_task_point, task: task, assessment_participation: participation,
                                       points: 3)
      end

      page = render_inline(component)

      expect(page.css("td.grade-col i.bi-exclamation-triangle-fill")).to be_empty
      expect(page.css(".alert-warning")).to be_empty
    end
  end
end
