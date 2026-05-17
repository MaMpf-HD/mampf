require "rails_helper"
describe SubmissionsController do
  let(:user)        { create(:user) }
  let(:lecture)     { create(:lecture) }
  let(:assignment)  { create(:assignment, lecture: lecture) }
  let(:tutorial)    { create(:tutorial, lecture: lecture) }
  let(:submission)  { create(:submission, assignment: assignment, tutorial: tutorial) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(Flipper).to receive(:enabled?).with(:roster_maintenance).and_return(true)
    allow_any_instance_of(Lecture).to receive(:has_rosterized_tutorials?).and_return(true)
    allow(user).to receive(:tutorial_rosterized).and_return(tutorial)
    controller.params = ActionController::Parameters.new(submission: { tutorial_id: tutorial.id,
                                                                       assignment_id: assignment.id })
  end

  describe "#submission_create_params" do
    it "overrides tutorial_id with rosterized tutorial when feature is enabled and lecture has rosterized tutorials" do
      permitted = controller.send(:submission_create_params)
      expect(permitted[:tutorial_id]).to eq(tutorial.id)
    end
  end

  describe "#submission_update_params" do
    it "overrides tutorial_id with rosterized tutorial when feature is enabled and lecture has rosterized tutorials" do
      controller.instance_variable_set(:@submission, submission)
      permitted = controller.send(:submission_update_params)
      expect(permitted[:tutorial_id]).to eq(tutorial.id)
    end
  end
end
