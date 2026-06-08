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
    allow_any_instance_of(User).to receive(:tutorial_rosterized).and_return(tutorial)
  end

  context "when feature flag roster_maintenance is enabled" do
    before do
      Flipper.enable(:roster_maintenance)
      Flipper.enable(:registration_campaigns)
    end

    after do
      Flipper.disable(:roster_maintenance)
      Flipper.disable(:registration_campaigns)
    end

    context "when lecture has roster-eligible tutorials" do
      before do
        allow_any_instance_of(Lecture).to receive(:roster_eligible_tutorials?).and_return(true)
        allow(user).to receive(:tutorial_rosterized).and_return(tutorial)
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

    context "when lecture has no roster-eligible tutorials" do
      before do
        allow_any_instance_of(Lecture).to receive(:roster_eligible_tutorials?).and_return(false)
        allow(user).to receive(:tutorial_rosterized).and_return(nil)
      end

      describe "#submission_create_params" do
        before do
          controller.params = ActionController::Parameters.new(
            submission: { tutorial_id: other_tutorial.id,
                          assignment_id: assignment.id }
          )
        end
        it "uses tutorial_id with from the params" do
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
        it "uses tutorial_id with from the params" do
          controller.instance_variable_set(:@submission, submission)
          permitted = controller.send(:submission_update_params)
          expect(permitted[:tutorial_id]).to eq(other_tutorial.id)
        end
      end
    end
  end

  context "when feature flag not enabled" do
    describe "#submission_create_params" do
      before do
        controller.params = ActionController::Parameters.new(
          submission: { tutorial_id: other_tutorial.id,
                        assignment_id: assignment.id }
        )
      end
      it "uses tutorial_id with from the params" do
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
      it "uses tutorial_id with from the params" do
        controller.instance_variable_set(:@submission, submission)
        permitted = controller.send(:submission_update_params)
        expect(permitted[:tutorial_id]).to eq(other_tutorial.id)
      end
    end
  end
end
