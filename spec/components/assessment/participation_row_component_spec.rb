require "rails_helper"

RSpec.describe(ParticipationRowComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:tutor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  let(:lecture) { create(:lecture, teacher: teacher, submission_grace_period: 70) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: lecture) }

  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end
  let(:participation) do
    create(:assessment_participation, :submitted,
           assessment: assessment, user: student, tutorial: tutorial)
  end

  let(:component_tutor) do
    described_class.new(participation: participation, assessment: assessment,
                        grading_scope: tutorial)
  end

  let(:component_teacher) do
    described_class.new(participation: participation, assessment: assessment,
                        grading_scope: lecture)
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
          described_class.new(participation: orphan_participation, assessment: assessment,
                              grading_scope: tutorial)
        end.to raise_error(ParticipationRowComponent::MissingUserError)
      end
    end

    context "when grading_scope is a Tutorial" do
      it "sets @tutorial" do
        expect(component_tutor.instance_variable_get(:@tutorial)).to eq(tutorial)
      end

      it "sets @mode to tutor" do
        expect(component_tutor.instance_variable_get(:@mode)).to eq("tutor")
      end
    end

    context "when grading_scope is a Lecture" do
      it "sets @lecture from the assessable's lecture" do
        expect(component_teacher.instance_variable_get(:@lecture)).to eq(assignment.lecture)
      end

      it "sets @mode to teacher" do
        expect(component_teacher.instance_variable_get(:@mode)).to eq("teacher")
      end

      it "leaves @tutorial nil" do
        expect(component_teacher.instance_variable_get(:@tutorial)).to be_nil
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

    context "when flipper is enabled and assignment is assessable" do
      before do
        allow(assignment).to receive(:assessable?).and_return(true)
      end

      it "returns true" do
        expect(component_tutor.grading_enabled?).to eq(true)
      end
    end
  end

  describe "#allow_grading?" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
    end

    context "before deadline" do
      it "returns false" do
        expect(component_tutor.allow_grading?).to eq(false)
      end
    end

    context "after deadline and before grace period" do
      before { Timecop.travel(2.hours.from_now) }
      after { Timecop.return }

      it "returns false" do
        expect(component_tutor.allow_grading?).to eq(false)
      end
    end

    context "after grace period" do
      before { Timecop.travel(3.hours.from_now) }
      after { Timecop.return }

      it "returns true" do
        expect(component_tutor.allow_grading?).to eq(true)
      end
    end
  end

  describe "#tasks" do
    let!(:task) { create(:assessment_task, assessment: assessment) }

    it "returns persisted tasks from the assessable's assessment" do
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

    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "includes the task's id in the input name" do
      html = component_tutor.task_points_participation_input(task, true)
      expect(html).to include("task_points[#{task.id}]")
    end

    it "does not cap the input at the task's max_points, allowing bonus points" do
      html = component_tutor.task_points_participation_input(task, true)
      expect(html).not_to include("max=")
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

    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

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
      expect(html).to include("fa-save")
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

  describe "#can_enter_points?" do
    context "when grading_scope is a Tutorial" do
      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_tutor)
        end

        it "returns true" do
          expect(component_tutor.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is not an admin but is the tutor for that tutorial" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_tutor)
        end

        it "returns true" do
          expect(component_tutor.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is not an admin and not the tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_tutor)
        end

        it "returns false" do
          expect(component_tutor.can_enter_points?).to eq(false)
        end
      end
    end

    context "when grading_scope is a Lecture" do
      context "when current_user is not an admin but is the teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_enter_points?).to eq(true)
        end
      end

      context "when current_user is not an admin, not the teacher, but is a tutor in the lecture" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_teacher)
        end

        it "returns false" do
          expect(component_teacher.can_enter_points?).to eq(false)
        end
      end

      context "when current_user is not an admin, not the teacher, and is a student" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_teacher)
        end

        it "returns false" do
          expect(component_teacher.can_enter_points?).to eq(false)
        end
      end
    end

    context "when grading_scope is not a recognized type" do
      let(:component_unknown) do
        described_class.new(participation: participation,
                            assessment: assessment,
                            grading_scope: "not_a_scope")
      end

      before do
        allow(vc_test_controller).to receive(:current_user).and_return(student)
        render_inline(component_unknown)
      end

      it "does not raise and returns false for a non-admin" do
        expect(component_unknown.can_enter_points?).to eq(false)
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

  describe "rendering save/refresh urls" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "posts the row's points to its own participation" do
      expect(rendered_content).to include("/participations/#{participation.id}/point_participation")
      expect(rendered_content)
        .to include("/participations/#{participation.id}/refresh_point_participation")
    end
  end

  # One row per person on the roster: a sheet taken on paper, one never handed
  # in, and one the worker has not written a participation for yet all sit in
  # the table, and the hand-in column says which it is.
  describe "the hand-in column" do
    before { allow(vc_test_controller).to receive(:current_user).and_return(tutor) }

    it "offers to record a paper hand-in on a row nothing was handed in for" do
      participation.update!(submitted_at: nil)
      render_inline(component_tutor)

      expect(rendered_content).to include(I18n.t("assessment.grading_tutorial.paper_hand_in"))
      expect(rendered_content).to include(
        I18n.t("student_performance.records.columns.not_submitted")
      )
    end

    it "offers to take a paper hand-in back while no points sit on it" do
      participation.update!(submitted_at: 1.day.ago)
      render_inline(component_tutor)

      expect(rendered_content)
        .to include(I18n.t("assessment.grading_tutorial.paper_hand_in_remove"))
      expect(rendered_content).to include(
        I18n.t("student_performance.records.columns.pending_grading")
      )
    end

    it "keeps a paper hand-in that carries points" do
      task = create(:assessment_task, assessment: assessment)
      participation.update!(submitted_at: 1.day.ago)
      Timecop.travel(3.hours.from_now) do
        create(:assessment_task_point, task: task, points: 3,
                                       assessment_participation: participation)
      end
      render_inline(described_class.new(participation: participation.reload,
                                        assessment: assessment, grading_scope: tutorial))

      expect(rendered_content).to include(I18n.t("assessment.grading_tutorial.paper_hand_in_kept"))
      expect(rendered_content).not_to include("remove_participated")
    end

    it "draws a row for somebody without a participation yet, with nothing to type into" do
      unsaved = Assessment::Participation.new(assessment: assessment, user: student,
                                              tutorial: tutorial)
      component = described_class.new(participation: unsaved, assessment: assessment,
                                      grading_scope: tutorial)
      render_inline(component)

      expect(component.row_id).to eq("participation-row-user-#{student.id}")
      expect(component.points_enterable?).to be(false)
      expect(rendered_content).to include(I18n.t("assessment.grading_tutorial.paper_hand_in"))
      expect(rendered_content).not_to include("point_participation")
    end

    # Points go where the sheet is: somebody who moved into this group after
    # handing in elsewhere is marked there, not here.
    it "locks a row whose sheet another group holds" do
      elsewhere = create(:tutorial, lecture: lecture)
      participation.update!(tutorial: elsewhere)
      component = described_class.new(participation: participation, assessment: assessment,
                                      grading_scope: tutorial)
      render_inline(component)

      expect(component.elsewhere?).to be(true)
      expect(component.points_enterable?).to be(false)
      expect(rendered_content).not_to include(I18n.t("assessment.grading_tutorial.paper_hand_in"))
    end

    it "lets the lecturer's table mark anybody" do
      elsewhere = create(:tutorial, lecture: lecture)
      participation.update!(tutorial: elsewhere)
      component = described_class.new(participation: participation, assessment: assessment,
                                      grading_scope: lecture)

      expect(component.elsewhere?).to be(false)
      expect(component.points_enterable?).to be(true)
    end

    it "opens the points only once the sheet is marked as handed in" do
      participation.update!(submitted_at: nil)
      component = described_class.new(participation: participation, assessment: assessment,
                                      grading_scope: tutorial)

      expect(component.points_enterable?).to be(false)
      participation.update!(submitted_at: 1.day.ago)
      expect(component.points_enterable?).to be(true)
    end

    it "offers nothing on an excused row" do
      participation.update!(submitted_at: nil)
      participation.update!(status: :exempt)
      component = described_class.new(participation: participation, assessment: assessment,
                                      grading_scope: tutorial)
      render_inline(component)

      expect(component.points_enterable?).to be(false)
      expect(rendered_content).not_to include(I18n.t("assessment.grading_tutorial.paper_hand_in"))
      expect(rendered_content).to include(I18n.t("student_performance.records.columns.exempt"))
    end
  end
end
