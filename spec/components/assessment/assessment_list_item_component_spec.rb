require "rails_helper"

RSpec.describe(AssessmentListItemComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  before do
    Flipper.enable(:assessment_grading)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  context "with an assignment" do
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:component) { described_class.new(assessable: assignment, lecture: lecture) }

    it "renders the component" do
      render_inline(component)
      expect(rendered_content).to include(CGI.escapeHTML(assignment.title))
    end

    it "returns the correct show path" do
      render_inline(component)
      expect(component.show_path).to eq(
        Rails.application.routes.url_helpers.assessment_assessment_path(
          assessment.id,
          assessable_type: "Assignment",
          assessable_id: assignment.id
        )
      )
    end

    it "returns medium title when assignment has medium" do
      medium = create(:medium, :with_description, :with_editors,
                      teachable: lecture, released: "all", sort: "Script")
      assignment.update!(medium: medium)
      expect(component.medium_title).to eq(medium.local_title_for_viewers)
    end

    it "returns file type" do
      expect(component.file_type).to eq(assignment.accepted_file_type)
    end

    it "returns deadline formatted" do
      expect(component.deadline_display).to eq(I18n.l(assignment.deadline, format: :short))
    end

    it "returns tasks count" do
      assessment.update!(requires_points: true)
      Assessment::Task.create!(assessment: assessment, max_points: 1)
      Assessment::Task.create!(assessment: assessment, max_points: 1)
      expect(component.tasks_count).to eq(2)
    end

    describe "#total_points_display" do
      it "returns dash when requires_points is false" do
        assessment.update!(requires_points: false)
        expect(component.total_points_display).to eq("—")
      end

      it "returns dash when no tasks exist" do
        assessment.update!(requires_points: true)
        expect(component.total_points_display).to eq("—")
      end

      it "returns integer format for whole number points" do
        assessment.update!(requires_points: true)
        Assessment::Task.create!(assessment: assessment, max_points: 10)
        Assessment::Task.create!(assessment: assessment, max_points: 5)
        expect(component.total_points_display)
          .to eq("15 #{I18n.t("assessment.task.points_abbrev")}")
      end

      it "returns decimal format for fractional points" do
        assessment.update!(requires_points: true)
        Assessment::Task.create!(assessment: assessment, max_points: 10.5)
        Assessment::Task.create!(assessment: assessment, max_points: 5)
        expect(component.total_points_display)
          .to eq("15.5 #{I18n.t("assessment.task.points_abbrev")}")
      end
    end

    describe "edit and delete paths for non-legacy assignments" do
      it "returns nil for edit_path" do
        expect(component.edit_path).to be_nil
      end

      it "returns nil for delete_path" do
        expect(component.delete_path).to be_nil
      end
    end
  end

  context "with a legacy assignment" do
    let(:assignment) do
      Flipper.disable(:assessment_grading)
      a = create(:valid_assignment, lecture: lecture)
      Flipper.enable(:assessment_grading)
      a
    end
    let(:component) { described_class.new(assessable: assignment, lecture: lecture, legacy: true) }

    it "returns edit path for legacy assignment" do
      render_inline(component)
      expect(component.edit_path).to eq(
        Rails.application.routes.url_helpers.edit_assignment_path(assignment)
      )
    end

    it "returns delete path for legacy assignment" do
      render_inline(component)
      expect(component.delete_path).to eq(
        Rails.application.routes.url_helpers.assignment_path(assignment)
      )
    end

    it "returns # as show_path when no assessment" do
      expect(component.show_path).to eq("#")
    end

    it "returns 0 for tasks_count when no assessment" do
      expect(component.tasks_count).to eq(0)
    end
  end

  context "without assessment" do
    let(:assignment) do
      Flipper.disable(:assessment_grading)
      a = create(:valid_assignment, lecture: lecture)
      Flipper.enable(:assessment_grading)
      a
    end
    let(:component) { described_class.new(assessable: assignment, lecture: lecture) }

    it "returns # as show_path" do
      expect(component.show_path).to eq("#")
    end
  end

end
