require "rails_helper"

RSpec.describe(TutorialPointingTableComponent, type: :component) do
  let(:lecture) { create(:lecture, submission_grace_period: 70) }
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

  describe "when grading_scope is a Tutorial" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: tutorial)
    end

    describe "#grading_enabled?" do
      context "when assignment is assessable" do
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

  describe "when grading_scope is a Lecture" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: lecture)
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
        grouped = described_class.new(assignment: assignment, grading_scope: lecture)
                                 .instance_variable_get(:@submissions_by_tutorial)
        expect(grouped[tutorial]).to include(submission)
      end

      it "groups non-submitters by tutorial via their preloaded participation" do
        user = create(:confirmed_user)
        participation = create(:assessment_participation, assessment: assessment, user: user,
                                                          tutorial: tutorial)
        allow(assignment).to receive(:non_submitters_in_tutorials).and_return([user])

        grouped = described_class.new(assignment: assignment, grading_scope: lecture)
                                 .instance_variable_get(:@non_submitters_by_tutorial)
        expect(grouped[tutorial]).to include(user)
        participation # keep reference so rubocop doesn't flag unused let
      end
    end

    describe "rendering" do
      it "renders the grading table" do
        render_inline(component)
        expect(rendered_content).to include("grading-table")
      end
    end
  end

  describe "#preload_non_submitter_participations" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: tutorial)
    end
    let(:user) { create(:confirmed_user) }
    let!(:participation) do
      create(:assessment_participation, assessment: assessment, user: user, tutorial: tutorial)
    end

    it "returns a hash keyed by user_id" do
      result = component.preload_non_submitter_participations([user])
      expect(result[user.id]).to eq(participation)
    end

    it "preloads task_points so no further query is issued" do
      preloaded = component.preload_non_submitter_participations([user])[user.id]
      query_count = 0
      callback = lambda { |*, payload|
        query_count += 1 unless payload[:sql].match?(/SCHEMA|TRANSACTION/)
      }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        preloaded.task_points.to_a
      end
      expect(query_count).to eq(0)
    end
  end

  describe "#mark_as_participated_link" do
    let(:component) do
      described_class.new(assignment: assignment, grading_scope: tutorial)
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

  describe "#users_movement_map" do
    let(:tutorial2) { create(:tutorial, lecture: lecture) }

    let(:student1) { create(:confirmed_user) }
    let(:student2) { create(:confirmed_user) }
    let(:student3) { create(:confirmed_user) }
    let(:foreign_submission) do
      create(:submission, assignment: assignment, tutorial: tutorial)
        .tap do |s|
        s.users << student2
        s.users << student3
      end
    end

    let(:component) do
      described_class.new(assignment: assignment, grading_scope: tutorial)
    end

    before do
      create(:tutorial_membership, tutorial: tutorial, user: student1)
      create(:tutorial_membership, tutorial: tutorial, user: student2)
      create(:tutorial_membership, tutorial: tutorial, user: student3)
    end

    context "when assignment is past deadline" do
      before do
        Timecop.travel(2.hours.from_now)
      end
      after do
        Timecop.return
      end

      it "memoizes the result and only computes it once across multiple calls" do
        movement_map = { 1 => { participated_tutorial_id: 1, new_tutorial_id: 2 } }

        expect_any_instance_of(AssessmentHelper).to receive(:calculate_user_movement_map_assignment)
          .with(assignment, anything)
          .once
          .and_return(movement_map)

        render_inline(component)

        first_call = component.users_movement_map
        second_call = component.users_movement_map

        expect(first_call).to eq(movement_map)
        expect(second_call).to eq(movement_map)
      end

      it "caches the value in the helpers' users_movement_map_cache" do
        movement_map = { 1 => { old_tutorial: "A", new_tutorial: "B" } }
        expect_any_instance_of(AssessmentHelper).to receive(:calculate_user_movement_map_assignment)
          .and_return(movement_map)

        render_inline(component)

        component.users_movement_map

        expect(component.helpers.users_movement_map_cache[assignment.id]).to eq(movement_map)
      end
    end
  end
end
