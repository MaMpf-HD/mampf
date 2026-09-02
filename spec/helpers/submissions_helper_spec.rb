require "rails_helper"

RSpec.describe(SubmissionsHelper, type: :helper) do
  let(:user) { create(:confirmed_user) }
  let(:lecture)          { create(:lecture) }
  let(:other_lecture)    { create(:lecture) }
  let(:tutorial)         { create(:tutorial, lecture: lecture) }
  let(:other_tutorial)   { create(:tutorial, lecture: other_lecture) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#enabled_roster_for_lecture?" do
    before { create(:tutorial_membership, tutorial: tutorial) } # makes lecture roster-eligible

    it "only queries roster_managed? once per lecture (memoized)" do
      expect(lecture).to receive(:roster_managed?).once.and_call_original

      first  = helper.enabled_roster_for_lecture?(lecture)
      second = helper.enabled_roster_for_lecture?(lecture)

      expect(first).to eq(true)
      expect(second).to eq(true)
    end

    it "computes independently per lecture (no cross-lecture leakage)" do
      # other_lecture has no roster-eligible tutorials
      expect(helper.enabled_roster_for_lecture?(lecture)).to eq(true)
      expect(helper.enabled_roster_for_lecture?(other_lecture)).to eq(false)
    end
  end

  describe "#rostered_tutorial_for" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "only queries rostered_tutorial_in once per lecture (memoized)" do
      expect(user).to receive(:rostered_tutorial_in).once.with(lecture).and_return(tutorial)

      first  = helper.rostered_tutorial_for(lecture)
      second = helper.rostered_tutorial_for(lecture)

      expect(first).to eq(tutorial)
      expect(second).to eq(tutorial)
    end

    it "computes independently per lecture (no cross-lecture leakage)" do
      create(:tutorial_membership, tutorial: other_tutorial, user: user)

      expect(helper.rostered_tutorial_for(lecture)).to eq(tutorial)
      expect(helper.rostered_tutorial_for(other_lecture)).to eq(other_tutorial)
    end

    it "returns nil without querying rostered_tutorial_in when lecture is not roster-eligible" do
      not_eligible_lecture = create(:lecture)
      expect(user).not_to receive(:rostered_tutorial_in)

      expect(helper.rostered_tutorial_for(not_eligible_lecture)).to be_nil
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

  describe "#roster_cache" do
    it "returns the same hash across multiple calls within one helper instance" do
      first  = helper.roster_cache
      second = helper.roster_cache

      expect(first).to equal(second) # same object, not just equal value
    end
  end
end
