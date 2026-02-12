require "rails_helper"

RSpec.describe(AssessmentDashboardComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  shared_examples "visible tab" do |tab_key|
    it "renders the #{tab_key} tab" do
      render_inline(component)
      expect(rendered_content).to include(
        "data-bs-target=\"##{component.dom_prefix}-#{tab_key}\""
      )
    end
  end

  shared_examples "hidden tab" do |tab_name|
    it "does not render the #{tab_name} tab" do
      render_inline(component)
      expect(rendered_content).not_to include("-#{tab_name}\"")
    end
  end

  shared_examples "common header" do
    it "renders the assessable title" do
      render_inline(component)
      expect(rendered_content).to include(CGI.escapeHTML(assessable.title))
    end

    it "renders a back link" do
      render_inline(component)
      expect(rendered_content).to include(I18n.t("back"))
      expect(rendered_content).to include(component.back_path)
    end
  end

  context "with an assignment" do
    let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:assessable) { assignment }
    let(:component) do
      described_class.new(assessable: assignment, assessment: assessment,
                          lecture: lecture)
    end

    include_examples "common header"
    include_examples "visible tab", "settings"
    include_examples "visible tab", "tasks"
    include_examples "visible tab", "submissions"
    include_examples "visible tab", "points"
    include_examples "visible tab", "statistics"
    include_examples "hidden tab", "overview"
    include_examples "hidden tab", "roster"
    include_examples "hidden tab", "grades"

    describe "#tabs" do
      it "returns the correct tab keys" do
        keys = component.tabs.map(&:key)
        expect(keys).to eq(
          ["settings", "tasks", "submissions", "points", "statistics"]
        )
      end
    end

    describe "submissions tab (conditional)" do
      it "is included when requires_submission is true" do
        assessment.update!(requires_submission: true)
        keys = described_class.new(
          assessable: assignment, assessment: assessment, lecture: lecture
        ).tabs.map(&:key)
        expect(keys).to include("submissions")
      end

      it "is excluded when requires_submission is false" do
        assessment.update!(requires_submission: false)
        keys = component.tabs.map(&:key)
        expect(keys).not_to include("submissions")
      end

      context "when requires_submission is true" do
        before { assessment.update!(requires_submission: true) }

        it "renders the submissions tab" do
          render_inline(component)
          expect(rendered_content).to include("-submissions\"")
        end

        it "renders GradingOverviewComponent in the submissions pane" do
          render_inline(component)
          expect(rendered_content).to include("grading_overview_component")
        end
      end

      context "when requires_submission is false" do
        before { assessment.update!(requires_submission: false) }

        it "does not render the submissions tab" do
          render_inline(component)
          expect(rendered_content).not_to include(
            "#{component.dom_prefix}-submissions\""
          )
        end
      end
    end

    describe "#default_tab" do
      it 'returns "settings"' do
        expect(component.default_tab).to eq("settings")
      end
    end

    describe "#back_path" do
      it "points to the assessments index" do
        render_inline(component)
        expected = Rails.application.routes.url_helpers
                        .assessment_assessments_path(lecture_id: lecture.id)
        expect(component.back_path).to eq(expected)
      end
    end

    describe "#subtitle" do
      it "returns nil" do
        render_inline(component)
        expect(component.subtitle).to be_nil
      end
    end

    it "activates the settings tab by default" do
      render_inline(component)
      expect(rendered_content).to match(
        /nav-link\s+active[^>]*data-bs-target="#[^"]*-settings"/m
      )
    end

    it "activates a custom tab when specified" do
      custom = described_class.new(
        assessable: assignment, assessment: assessment,
        lecture: lecture, active_tab: "tasks"
      )
      render_inline(custom)
      expect(rendered_content).to match(
        /nav-link\s+active[^>]*data-bs-target="#[^"]*-tasks"/m
      )
    end
  end

  context "with an exam" do
    let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
    let(:exam) { create(:exam, lecture: lecture) }
    let(:assessment) { exam.reload.assessment }
    let(:assessable) { exam }
    let(:component) do
      described_class.new(assessable: exam, assessment: assessment,
                          lecture: lecture)
    end

    include_examples "common header"
    include_examples "visible tab", "overview"
    include_examples "visible tab", "settings"
    include_examples "visible tab", "tasks"
    include_examples "visible tab", "points"
    include_examples "visible tab", "grades"
    include_examples "visible tab", "roster"
    include_examples "visible tab", "statistics"

    describe "#tabs" do
      it "returns the correct tab keys" do
        keys = component.tabs.map(&:key)
        expect(keys).to eq(
          ["overview", "settings", "tasks", "points", "grades", "roster", "statistics"]
        )
      end
    end

    it "renders GradeTableComponent in the grades pane" do
      render_inline(component)
      expect(rendered_content).to include("grade_table_component")
    end

    describe "#default_tab" do
      it 'returns "overview"' do
        expect(component.default_tab).to eq("overview")
      end
    end

    describe "#back_path" do
      it "points to the exams index" do
        render_inline(component)
        expected = Rails.application.routes.url_helpers
                        .exams_path(lecture_id: lecture.id)
        expect(component.back_path).to eq(expected)
      end
    end

    describe "#subtitle" do
      it "returns lecture title and term info" do
        render_inline(component)
        expect(component.subtitle).to eq(
          "#{lecture.title} · #{lecture.term_teacher_info}"
        )
      end
    end

    it "activates the overview tab by default" do
      render_inline(component)
      expect(rendered_content).to match(
        /nav-link\s+active[^>]*data-bs-target="#[^"]*-overview"/m
      )
    end
  end

  context "with a talk" do
    let(:seminar) { create(:seminar, teacher: teacher) }
    let(:talk) { create(:talk, lecture: seminar) }
    let(:assessment) { talk.reload.assessment }
    let(:assessable) { talk }
    let(:component) do
      described_class.new(assessable: talk, assessment: assessment,
                          lecture: seminar)
    end

    include_examples "common header"
    include_examples "visible tab", "grades"
    include_examples "hidden tab", "overview"
    include_examples "hidden tab", "settings"
    include_examples "hidden tab", "tasks"
    include_examples "hidden tab", "roster"
    include_examples "hidden tab", "submissions"
    include_examples "hidden tab", "points"
    include_examples "hidden tab", "statistics"

    describe "#tabs" do
      it "returns the correct tab keys" do
        keys = component.tabs.map(&:key)
        expect(keys).to eq(["grades"])
      end
    end

    it "renders exactly one tab" do
      render_inline(component)
      expect(rendered_content.scan("nav-link").size).to eq(1)
    end

    it "renders GradeTableComponent in the grades pane" do
      render_inline(component)
      expect(rendered_content).to include("grade_table_component")
    end

    describe "#default_tab" do
      it 'returns "grades"' do
        expect(component.default_tab).to eq("grades")
      end
    end

    describe "#back_path" do
      it "points to the assessments index" do
        render_inline(component)
        expected = Rails.application.routes.url_helpers
                        .assessment_assessments_path(lecture_id: seminar.id)
        expect(component.back_path).to eq(expected)
      end
    end

    describe "#subtitle" do
      it "returns nil" do
        render_inline(component)
        expect(component.subtitle).to be_nil
      end
    end

    it "activates the grades tab by default" do
      render_inline(component)
      expect(rendered_content).to match(
        /nav-link\s+active[^>]*data-bs-target="#[^"]*-grades"/m
      )
    end
  end

  describe "#dom_prefix" do
    let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }

    it "includes the assessable type and id" do
      comp = described_class.new(
        assessable: assignment, assessment: assessment, lecture: lecture
      )
      expect(comp.dom_prefix).to eq(
        "dashboard-assignment-#{assignment.id}"
      )
    end

    it "generates unique prefixes for different assessables" do
      exam = create(:exam, lecture: lecture)
      comp_a = described_class.new(
        assessable: assignment, assessment: assessment, lecture: lecture
      )
      comp_e = described_class.new(
        assessable: exam, assessment: exam.reload.assessment, lecture: lecture
      )
      expect(comp_a.dom_prefix).not_to eq(comp_e.dom_prefix)
    end
  end

  describe "#tab_active?" do
    let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }

    it "returns true for the active tab" do
      comp = described_class.new(
        assessable: assignment, assessment: assessment,
        lecture: lecture, active_tab: "tasks"
      )
      expect(comp.tab_active?("tasks")).to be(true)
    end

    it "returns false for inactive tabs" do
      comp = described_class.new(
        assessable: assignment, assessment: assessment,
        lecture: lecture, active_tab: "tasks"
      )
      expect(comp.tab_active?("settings")).to be(false)
    end
  end
end
