require "rails_helper"

RSpec.describe(ParticipationRowComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:tutor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: lecture) }

  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end
  let(:participation) do
    create(:assessment_participation, assessment: assessment, user: student, tutorial: tutorial)
  end
  let(:component_tutor) do
    described_class.new(participation: participation, assignment: assignment,
                        tutorial: tutorial, mode: "tutor")
  end

  let(:component_teacher) do
    described_class.new(participation: participation, assignment: assignment,
                        tutorial: tutorial, mode: "teacher")
  end

  before do
    assignment.reload
    assessment.reload
  end

  describe "#initialize" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
    end
    context "when participation has no user" do
      let(:orphan_participation) do
        create(:assessment_participation, assessment: assessment, user: student, tutorial: tutorial)
          .tap { |p| allow(p).to receive(:user).and_return(nil) }
      end

      it "raises MissingUserError" do
        expect do
          described_class.new(participation: orphan_participation, assignment: assignment,
                              tutorial: tutorial, mode: "tutor")
        end.to raise_error(ParticipationRowComponent::MissingUserError)
      end
    end

    context "when mode is tutor" do
      it "sets @tutorial" do
        expect(component_tutor.instance_variable_get(:@tutorial)).to eq(tutorial)
      end

      it "does not set @lecture" do
        expect(component_tutor.instance_variable_get(:@lecture)).to be_nil
      end
    end

    context "when mode is teacher" do
      it "sets @lecture from the assignment's lecture" do
        expect(component_teacher.instance_variable_get(:@lecture)).to eq(assignment.lecture)
      end
    end

    context "when mode is not passed" do
      let(:default_mode_component) do
        described_class.new(participation: participation, assignment: assignment,
                            tutorial: tutorial)
      end

      it "defaults to tutor mode" do
        expect(default_mode_component.instance_variable_get(:@mode)).to eq("tutor")
      end
    end
  end

  describe "#row_id" do
    it "returns the correct row id" do
      expect(component_tutor.row_id).to eq("participation-row-#{participation.id}")
    end
  end

  describe "#grading_enabled?" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
    end
    context "when flipper is disabled" do
      before { Flipper.disable(:assessment_grading) }

      it "returns false" do
        expect(component_tutor.grading_enabled?).to eq(false)
      end
    end

    context "when flipper is enabled and assignment is assessable" do
      before do
        Flipper.enable(:assessment_grading)
        allow(assignment).to receive(:assessable?).and_return(true)
      end
      after { Flipper.disable(:assessment_grading) }

      it "returns true" do
        expect(component_tutor.grading_enabled?).to eq(true)
      end
    end
  end

  describe "#allow_grading?" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
    end
    context "when assignment is active" do
      before { allow(assignment).to receive(:active?).and_return(true) }

      it "returns false" do
        expect(component_tutor.allow_grading?).to eq(false)
      end
    end

    context "when assignment is not active" do
      before { allow(assignment).to receive(:active?).and_return(false) }

      it "returns true" do
        expect(component_tutor.allow_grading?).to eq(true)
      end
    end
  end

  describe "#badge_status_participation_color" do
    it "returns warning for pending" do
      expect(component_tutor.badge_status_participation_color(:pending)).to eq("warning")
    end

    it "returns success for reviewed" do
      expect(component_tutor.badge_status_participation_color(:reviewed)).to eq("success")
    end

    it "returns info for exempt" do
      expect(component_tutor.badge_status_participation_color(:exempt)).to eq("info")
    end

    it "returns info for absent" do
      expect(component_tutor.badge_status_participation_color(:absent)).to eq("info")
    end

    it "returns nil for unknown status" do
      expect(component_tutor.badge_status_participation_color(:unknown)).to be_nil
    end
  end

  describe "#badge_status_participation_class" do
    it "returns correct class string" do
      expect(component_tutor.badge_status_participation_class(:pending))
        .to eq("badge rounded-pill bg-warning")
    end
  end

  describe "#tasks" do
    let!(:task) { create(:assessment_task, assessment: assessment) }

    it "returns persisted tasks from assignment assessment" do
      expect(component_tutor.tasks).to eq(assignment.reload.assessment.persisted_tasks)
    end
  end

  describe "#extract_task_points_participation" do
    let!(:task) { create(:assessment_task, assessment: assessment) }

    before { participation }

    context "when task points exist" do
      it "returns the points" do
        graded_task = double("graded_task", task_id: task.id, points: 8.0)
        allow(participation).to receive(:graded_tasks_points).and_return([graded_task])
        expect(component_tutor.extract_task_points_participation(task)).to eq(8.0)
      end
    end

    context "when no task points exist" do
      it "returns nil" do
        graded_task = double("graded_task", task_id: task.id, points: nil)
        allow(participation).to receive(:graded_tasks_points).and_return([graded_task])
        expect(component_tutor.extract_task_points_participation(task)).to be_nil
      end
    end

    it "memoizes graded_tasks_points across multiple calls" do
      allow(participation).to receive(:graded_tasks_points).and_return([])
      component_tutor.extract_task_points_participation(task)
      component_tutor.extract_task_points_participation(task)
      expect(participation).to have_received(:graded_tasks_points).once
    end
  end

  describe "#task_points_participation_input" do
    let!(:task) { create(:assessment_task, assessment: assessment, max_points: 10) }

    it "includes the task's id in the input name" do
      html = component_tutor.task_points_participation_input(task, true)
      expect(html).to include("task_points[#{task.id}]")
    end

    context "when grading is not allowed" do
      it "disables the input" do
        html = component_tutor.task_points_participation_input(task, false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#task_points_participation_cell" do
    let!(:task) { create(:assessment_task, assessment: assessment, max_points: 10) }

    it "wraps the input in a td with the expected classes" do
      html = component_tutor.task_points_participation_cell(task, true)
      expect(html).to include("sticky-col task-col")
      expect(html).to include("task_points[#{task.id}]")
    end
  end

  describe "#save_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "renders a button with the save icon" do
      html = component_tutor.save_row_button(true)
      expect(html).to include("bi-save")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutor.save_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#refresh_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "renders a button with the refresh icon" do
      html = component_tutor.refresh_row_button(true)
      expect(html).to include("bi-arrow-clockwise")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutor.refresh_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#can_grade?" do
    context "when mode is tutor" do
      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_tutor)
        end
        after { allow(vc_test_controller).to receive(:current_user).and_return(tutor) }

        it "returns true" do
          expect(component_tutor.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin but a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_tutor)
        end
        it "returns true" do
          expect(component_tutor.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin and not a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_tutor)
        end

        it "returns false" do
          expect(component_tutor.can_grade?).to eq(false)
        end
      end
    end

    context "when mode is teacher" do
      context "when current_user is not an admin but a teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_grade?).to eq(true)
        end
      end

      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin, not a teacher but a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin, not a teacher but a student" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_teacher)
        end

        it "returns false" do
          expect(component_teacher.can_grade?).to eq(false)
        end
      end
    end
  end

  describe "rendering" do
    before do
      participation
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "renders the participation row" do
      expect(rendered_content).to include(component_tutor.row_id)
    end
  end
end
