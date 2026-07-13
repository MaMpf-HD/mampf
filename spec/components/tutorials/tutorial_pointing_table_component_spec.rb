require "rails_helper"

RSpec.describe(TutorialPointingTableComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end

  before do
    assignment.reload
    assessment.reload
  end

  describe "in tutor mode" do
    let(:component) do
      described_class.new(assignment: assignment, tutorial: tutorial, mode: "tutor")
    end

    describe "#grading_enabled?" do
      context "when flipper is disabled" do
        before { Flipper.disable(:assessment_grading) }

        it "returns false" do
          expect(component.grading_enabled?).to eq(false)
        end
      end

      context "when flipper is enabled and assignment is assessable" do
        before do
          Flipper.enable(:assessment_grading)
          allow(assignment).to receive(:assessable?).and_return(true)
        end
        after { Flipper.disable(:assessment_grading) }

        it "returns true" do
          expect(component.grading_enabled?).to eq(true)
        end
      end
    end

    describe "#tasks" do
      let!(:task) { create(:assessment_task, assessment: assessment) }

      it "returns persisted tasks from assignment assessment" do
        expect(component.tasks).to eq(assignment.reload.assessment.persisted_tasks)
      end
    end

    describe "#total_max_points" do
      context "when there are no tasks" do
        it "returns 0" do
          expect(component.total_max_points).to eq(0)
        end
      end

      context "when there are tasks with max_points" do
        before do
          create(:assessment_task, assessment: assessment, max_points: 10)
          create(:assessment_task, assessment: assessment, max_points: 5)
          assignment.reload
        end

        it "returns the sum of max points" do
          expect(component.total_max_points).to eq(15)
        end
      end
    end

    describe "#column_count" do
      it "returns 6 plus the number of tasks" do
        create(:assessment_task, assessment: assessment)
        assignment.reload
        expect(component.column_count).to eq(6 + component.tasks.count)
      end
    end

    describe "#grading_records?" do
      context "when there are submissions" do
        let!(:submission) do
          create(:submission, :with_manuscript,
                 assignment: assignment, tutorial: tutorial,
                 users: [create(:confirmed_user)])
        end

        it "returns true" do
          expect(component.grading_records?).to be_truthy
        end
      end

      context "when there are no submissions and no non-submitters with participation" do
        it "returns falsey" do
          expect(component.grading_records?).to be_falsey
        end
      end
    end

    describe "rendering" do
      it "renders the grading table" do
        render_inline(component)
        expect(rendered_content).to include("grading-table")
      end
    end
  end

  describe "in teacher mode (mode != 'tutor')" do
    let(:component) do
      described_class.new(assignment: assignment, mode: "teacher")
    end

    describe "initialization" do
      it "sets @lecture from the assignment's lecture" do
        expect(component.instance_variable_get(:@lecture)).to eq(assignment.lecture)
      end

      it "sets @tutorials from the lecture's tutorials" do
        tutorial
        expect(component.instance_variable_get(:@tutorials)).to include(tutorial)
      end

      it "groups submissions by tutorial" do
        submission = create(:submission, :with_manuscript,
                            assignment: assignment,
                            tutorial: tutorial,
                            users: [create(:confirmed_user)])
        assignment.reload
        grouped = component.instance_variable_get(:@submissions_by_tutorial)
        expect(grouped[tutorial]).to include(submission)
      end

      it "groups non-submitters by tutorial via their participation" do
        user = create(:confirmed_user)
        allow(assignment).to receive(:non_submitters_in_tutorials).and_return([user])
        participation = double("participation", tutorial: tutorial)
        allow(user).to receive(:assessment_participation_in_assignment)
          .with(assignment).and_return(participation)

        grouped = described_class.new(assignment: assignment, mode: "teacher")
                                 .instance_variable_get(:@non_submitters_by_tutorial)
        expect(grouped[tutorial]).to include(user)
      end
    end

    describe "rendering" do
      it "renders the grading table" do
        render_inline(component)
        expect(rendered_content).to include("grading-table")
      end
    end
  end

  describe "#mark_as_participated_link" do
    let(:component) do
      described_class.new(assignment: assignment, tutorial: tutorial, mode: "tutor")
    end
    let(:user) { create(:confirmed_user) }

    before { render_inline(component) }

    it "renders a link containing the mark-as-participated text" do
      html = component.mark_as_participated_link(user)
      expect(html).to include(component.send(:t,
                                             "assessment.grading_tutorial.mark_as_participated"))
    end

    it "includes a turbo_method patch data attribute" do
      html = component.mark_as_participated_link(user)
      expect(html).to include("data-turbo-method=\"patch\"")
    end
  end
end
