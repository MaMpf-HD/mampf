require "rails_helper"

RSpec.describe("Referrals Security", type: :request) do
  describe "GET /referrals/list_items" do
    let(:user) do
      create(:user, admin: true, consents: true, confirmed_at: Time.zone.now)
    end
    let(:parsed_response) { JSON.parse(response.body) }

    before do
      sign_in user
    end

    it "safely handles invalid model injections in teachable_id" do
      get list_items_path, params: { teachable_id: "Logger-1" }, xhr: true

      expect(response).to be_successful
      expect(parsed_response).to eq([])
    end

    it "safely handles malformed allowlisted teachable_id values" do
      get list_items_path, params: { teachable_id: "Course" }, xhr: true

      expect(response).to be_successful
      expect(parsed_response).to eq([])
    end

    it "returns items for valid teachable classes" do
      course = create(:course)
      medium = create(:course_medium, :with_toc_item, teachable: course)
      item = medium.items.first

      get list_items_path, params: { teachable_id: "Course-#{course.id}" }, xhr: true

      expect(response).to be_successful
      expect(parsed_response).to include(
        { "value" => item.id, "text" => item.title_within_course }
      )
    end
  end
end
