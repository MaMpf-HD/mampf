require "rails_helper"

# Tests for SubmissionsController methods
describe SubmissionsController do
  let(:user)        { create(:confirmed_user) }
  let(:lecture)     { create(:lecture) }
  let(:assignment)  { create(:assignment, lecture: lecture) }
  let(:tutorial)    { create(:tutorial, lecture: lecture) }
  let(:other_tutorial) { create(:tutorial, lecture: lecture) }
  let(:submission) { create(:submission, assignment: assignment, tutorial: tutorial) }

  before do
    sign_in user
  end

  context "when lecture has no roster-eligible tutorials" do
    describe "#submission_create_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: other_tutorial.id,
                        assignment_id: assignment.id }
        )
      end
      it "uses the tutorial_id from the params" do
        permitted = controller.send(:submission_create_params)
        expect(permitted[:tutorial_id]).to eq(other_tutorial.id)
      end
    end

    describe "#submission_update_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: other_tutorial.id,
                        assignment_id: assignment.id }
        )
      end
      it "uses the tutorial_id from the params" do
        controller.instance_variable_set(:@submission, submission)
        permitted = controller.send(:submission_update_params)
        expect(permitted[:tutorial_id]).to eq(other_tutorial.id)
      end
    end
  end

  context "when lecture has roster-eligible tutorials but user is not rostered" do
    before do
      # create a tutorial membership for another user in the same lecture
      # so that the lecture has roster-eligible tutorials,
      # but the user is not rostered in any of them
      other_user = create(:confirmed_user)
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: other_tutorial, user: other_user)
    end
    describe "#submission_create_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: other_tutorial.id,
                        assignment_id: assignment.id }
        )
      end

      it "raises an error instead of silently nilling out tutorial_id" do
        expect { controller.send(:submission_create_params) }
          .to raise_error(SubmissionsController::TutorialNotRosteredError)
      end
    end

    describe "#submission_update_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: other_tutorial.id,
                        assignment_id: assignment.id }
        )
        controller.instance_variable_set(:@submission, submission)
      end

      it "raises an error instead of silently nilling out tutorial_id" do
        expect { controller.send(:submission_update_params) }
          .to raise_error(SubmissionsController::TutorialNotRosteredError)
      end
    end
  end

  context "when lecture has roster-eligible tutorials and student is enrolled" do
    before do
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: tutorial, user: user)
    end
    describe "#submission_create_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: tutorial.id,
                        assignment_id: assignment.id }
        )
      end
      it "overrides tutorial_id with rosterized tutorial id" do
        permitted = controller.send(:submission_create_params)
        expect(permitted[:tutorial_id]).to eq(tutorial.id)
      end
    end

    describe "#submission_update_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: other_tutorial.id,
                        assignment_id: assignment.id }
        )
      end
      it "overrides tutorial_id with rosterized tutorial id" do
        controller.instance_variable_set(:@submission, submission)
        permitted = controller.send(:submission_update_params)
        expect(permitted[:tutorial_id]).to eq(tutorial.id)
      end
    end
  end
end
