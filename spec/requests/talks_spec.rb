require "rails_helper"

RSpec.describe("Talks", type: :request) do
  let(:user) { create(:confirmed_user) }
  # Needs to be a valid talk that the user can see. Talk belongs to a lecture.
  let(:lecture) { create(:lecture, teacher: user) }
  let(:talk) do
    create(:valid_talk, lecture: lecture, details: "<script>alert('xss-details')</script>",
                        description: "<script>alert('xss-description')</script>",
                        display_description: true)
  end

  before do
    sign_in user
  end

  describe "GET /talks/:id" do
    it "escapes or strips script tags in the talk details and description" do
      get talk_path(talk)
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('xss-details')</script>")
      expect(response.body).not_to include("<script>alert('xss-description')</script>")
    end
  end
end
