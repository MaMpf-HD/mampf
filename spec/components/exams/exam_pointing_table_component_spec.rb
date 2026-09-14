require "rails_helper"

RSpec.describe(ExamPointingTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let!(:assessment) { create(:assessment, requires_points: true, assessable: exam) }
  let!(:task) { create(:assessment_task, assessment: assessment, max_points: 10) }
  let(:component) { described_class.new(exam: exam.reload) }

  before { allow(vc_test_controller).to receive(:current_user).and_return(teacher) }

  describe "#rows" do
    let(:zoe) { create(:confirmed_user, name: "Zoe") }
    let(:adam) { create(:confirmed_user, name: "Adam") }

    before do
      create(:exam_roster_entry, exam: exam, user: zoe)
      create(:exam_roster_entry, exam: exam, user: adam)
    end

    it "has one row per candidate on the roster, by name" do
      expect(component.rows.map(&:user)).to eq([adam, zoe])
    end

    it "creates the participation a candidate does not have yet, and keeps one they have" do
      existing = create(:assessment_participation, assessment: assessment, user: zoe)

      expect { component.rows }.to change(Assessment::Participation, :count).by(1)
      expect(component.rows).to include(existing)
    end

    it "leaves somebody removed from the roster out" do
      exam.exam_roster_entries.find_by(user: zoe).update!(excluded_at: Time.current)

      expect(component.rows.map(&:user)).to eq([adam])
    end

    it "counts the rows' states for the summary" do
      create(:assessment_participation, assessment: assessment, user: zoe, status: :absent)

      expect(component.row_statuses).to contain_exactly(:pending_grading, :absent)
    end
  end

  describe "#layout" do
    it "is the exam's points table" do
      expect(component.layout.columns).to eq([:team, :status, :tasks, :total, :save])
    end
  end

  describe "rendering" do
    it "says so when nobody is on the roster yet" do
      expect(render_inline(component).text)
        .to include(I18n.t("assessment.grading_exam.no_candidates"))
    end

    it "draws the summary, the filters and a points input per task" do
      create(:exam_roster_entry, exam: exam, user: create(:confirmed_user, name: "Ada"))

      page = render_inline(component)

      expect(page.css("p#pointing-summary")).to be_present
      options = page.css("select[data-status-filter-target=status] option")
      expect(options.map { |o| o.text.strip })
        .to include(I18n.t("student_performance.records.columns.absent"))
      expect(page.css("input[type=number]").size).to eq(1)
      expect(page.css("tr[id^=pointing-participation-row-]").size).to eq(1)
    end

    it "cuts the rows into pages of 20 unless the reader picks another size" do
      create(:exam_roster_entry, exam: exam, user: create(:confirmed_user))

      page = render_inline(component)

      filter = page.css("[data-controller~=status-filter]").first
      expect(filter["data-status-filter-page-size-value"]).to eq("20")
      sizes = page.css("nav[data-status-filter-target=pager] select option")
      expect(sizes.pluck("value")).to eq(["10", "20", "50", "100"])
    end

    # A tutor correcting their own group's exams narrows the table to it.
    describe "the tutorial filter" do
      let(:tutorial) { create(:tutorial, lecture: lecture, title: "Group A") }
      let(:member) { create(:confirmed_user, name: "Ada") }
      let(:loner) { create(:confirmed_user, name: "Bob") }

      before do
        create(:tutorial_membership, tutorial: tutorial, user: member)
        create(:exam_roster_entry, exam: exam, user: member)
        create(:exam_roster_entry, exam: exam, user: loner)
      end

      it "offers the lecture's tutorials and marks each row with the candidate's" do
        page = render_inline(component)

        options = page.css("select[data-status-filter-target=tutorial] option")
        expect(options.map { |o| [o["value"], o.text.strip] })
          .to include([tutorial.id.to_s, "Group A"],
                      ["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")])
        rows = page.css("tr[data-status-filter-target=row]")
        expect(rows.pluck("data-status-filter-tutorial")).to eq([tutorial.id.to_s, ""])
      end
    end

    it "offers no tutorial filter for a lecture without tutorials" do
      create(:exam_roster_entry, exam: exam, user: create(:confirmed_user))

      page = render_inline(component)

      expect(page.css("select[data-status-filter-target=tutorial]")).to be_empty
    end
  end
end
