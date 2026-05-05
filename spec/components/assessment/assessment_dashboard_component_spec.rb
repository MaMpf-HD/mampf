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
    include_examples "visible tab", "points"
    include_examples "visible tab", "statistics"
    include_examples "hidden tab", "overview"
    include_examples "hidden tab", "roster"
    include_examples "hidden tab", "grades"

    describe "#tabs" do
      it "returns the correct tab keys" do
        keys = component.tabs.map(&:key)
        expect(keys).to eq(
          ["settings", "tasks", "points", "statistics"]
        )
      end
    end

    describe "submissions in statistics tab" do
      it "includes submission overview when requires_submission is true" do
        assessment.update!(requires_submission: true)
        render_inline(component)
        expect(rendered_content).to include("grading_overview_component")
      end

      it "does not include submission overview when requires_submission is false" do
        assessment.update!(requires_submission: false)
        comp = described_class.new(
          assessable: assignment, assessment: assessment, lecture: lecture
        )
        render_inline(comp)
        pane_id = "#{comp.dom_prefix}-statistics"
        pane_html = rendered_content[/id="#{pane_id}".*?(?=<div[^>]*id="#{comp.dom_prefix}-)/m] ||
                    rendered_content
        expect(pane_html).not_to include("grading_overview_component")
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
    include_examples "visible tab", "settings"
    include_examples "visible tab", "tasks"
    include_examples "visible tab", "points"
    include_examples "visible tab", "statistics"
    include_examples "hidden tab", "overview"
    include_examples "hidden tab", "roster"
    include_examples "hidden tab", "grades"

    describe "#tabs" do
      it "returns the correct tab keys" do
        keys = component.tabs.map(&:key)
        expect(keys).to eq(
          ["settings", "tasks", "points", "statistics"]
        )
      end

      context "when registration_campaigns is enabled" do
        before { Flipper.enable(:registration_campaigns) }
        after { Flipper.disable(:registration_campaigns) }

        it "includes the registration tab" do
          render_inline(component)
          keys = component.tabs.map(&:key)
          expect(keys).to eq(
            ["settings", "registration", "tasks", "points", "statistics"]
          )
        end
      end
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

    it "generates unique prefixes for different assessments" do
      other_assignment = create(:valid_assignment, lecture: lecture)
      comp_a = described_class.new(
        assessable: assignment, assessment: assessment, lecture: lecture
      )
      comp_b = described_class.new(
        assessable: other_assignment,
        assessment: other_assignment.reload.assessment,
        lecture: lecture
      )
      expect(comp_a.dom_prefix).not_to eq(comp_b.dom_prefix)
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
