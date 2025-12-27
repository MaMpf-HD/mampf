require "rails_helper"

RSpec.describe("Roster::Maintenance", type: :request) do
  let(:user) { create(:user, :admin) }
  let(:lecture) { create(:lecture) }

  before do
    sign_in user
  end

  describe "GET /lectures/:id/roster" do
    it "returns http success" do
      get lecture_roster_path(lecture)
      expect(response).to have_http_status(:success)
    end

    it "assigns group_type from params" do
      get lecture_roster_path(lecture, group_type: "tutorials")
      expect(assigns(:group_type)).to eq(:tutorials)
    end

    it "defaults group_type to :all" do
      get lecture_roster_path(lecture)
      expect(assigns(:group_type)).to eq(:all)
    end
  end
end
