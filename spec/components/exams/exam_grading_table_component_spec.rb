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
    expect(component.layout.columns)
      .to eq([:team, :status_compact, :total, :grade, :note, :graded_compact, :save])
  end

  it "draws a grade select, a note and the exemption dialog" do
    page = render_inline(component)

    expect(page.css("select[name=grade]").size).to eq(1)
    expect(page.css("td.note-col textarea").size).to eq(1)
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

    it "shows nothing once the scheme is applied" do
      draft.update!(applied_at: Time.current, applied_by: teacher)

      expect(render_inline(component).css("td.grade-col .badge")).to be_empty
    end
  end
end
