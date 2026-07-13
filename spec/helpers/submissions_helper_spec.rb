require "rails_helper"

RSpec.describe(SubmissionsHelper, type: :helper) do
  describe "#required_roster_for_submission?" do
    context "when flipper is enabled" do
      before { allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(true) }
      it { expect(helper.required_roster_for_submission?).to be(true) }
    end

    context "when flipper is disabled" do
      before { allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(false) }
      it { expect(helper.required_roster_for_submission?).to be(false) }
    end
  end

  describe "#extract_task_points" do
    let(:task) { instance_double("AssessmentTask", id: 1) }
    let(:other_task) { instance_double("AssessmentTask", id: 2) }
    let(:task_point) { instance_double("TaskPoint", task_id: 1, points: 7.5) }
    let(:submission) { instance_double("Submission") }

    before { allow(submission).to receive(:graded_tasks_points).and_return([task_point]) }

    it "returns points for matching task" do
      expect(helper.extract_task_points(submission, task)).to eq(7.5)
    end

    it "returns nil when task not found" do
      expect(helper.extract_task_points(submission, other_task)).to be_nil
    end

    it "returns nil when graded_tasks_points is empty" do
      allow(submission).to receive(:graded_tasks_points).and_return([])
      expect(helper.extract_task_points(submission, task)).to be_nil
    end
  end

  describe "#extract_task_points_participation" do
    let(:task) { instance_double("AssessmentTask", id: 1) }
    let(:other_task) { instance_double("AssessmentTask", id: 2) }
    let(:task_point) { instance_double("TaskPoint", task_id: 1, points: 4.0) }
    let(:participation) { instance_double("Participation") }

    before { allow(participation).to receive(:graded_tasks_points).and_return([task_point]) }

    it "returns points for matching task" do
      expect(helper.extract_task_points_participation(participation, task)).to eq(4.0)
    end

    it "returns nil when task not found" do
      expect(helper.extract_task_points_participation(participation, other_task)).to be_nil
    end

    it "returns nil when graded_tasks_points is empty" do
      allow(participation).to receive(:graded_tasks_points).and_return([])
      expect(helper.extract_task_points_participation(participation, task)).to be_nil
    end
  end

  describe "#enabled_roster_for_lecture?" do
    let(:lecture) { instance_double("Lecture") }

    context "when both flipper and lecture are eligible" do
      before do
        allow(Flipper).to receive(:enabled?).with(:roster_maintenance).and_return(true)
        allow(lecture).to receive(:roster_eligible_tutorials?).and_return(true)
      end

      it { expect(helper.enabled_roster_for_lecture?(lecture)).to be(true) }
    end

    context "when flipper is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(:roster_maintenance).and_return(false)
        allow(lecture).to receive(:roster_eligible_tutorials?).and_return(true)
      end

      it { expect(helper.enabled_roster_for_lecture?(lecture)).to be(false) }
    end

    context "when lecture is not eligible" do
      before do
        allow(Flipper).to receive(:enabled?).with(:roster_maintenance).and_return(true)
        allow(lecture).to receive(:roster_eligible_tutorials?).and_return(false)
      end

      it { expect(helper.enabled_roster_for_lecture?(lecture)).to be(false) }
    end
  end
end
