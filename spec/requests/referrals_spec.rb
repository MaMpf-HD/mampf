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

  describe "POST /referrals" do
    let(:student) { create(:confirmed_user) }
    let(:medium) { create(:valid_medium) }
    let(:medium_editor) { create(:confirmed_user) }
    let!(:link_item) do
      create(:item, sort: "link", medium: nil,
                    link: "https://legit.example", description: "Legit")
    end

    before { medium.editors << medium_editor }

    def create_referral_params(link)
      { referral: { item_id: link_item.id, medium_id: medium.id,
                    link: link, description: "Desc",
                    start_time: "0:00:00.000", end_time: "0:00:01.000" } }
    end

    it "lets an editor of the medium update the link item and create the referral" do
      sign_in medium_editor
      expect do
        post(referrals_path(format: :js), params: create_referral_params("https://new.example"))
      end.to change(Referral, :count).by(1)
      expect(link_item.reload.link).to eq("https://new.example")
    end

    it "does not let a non-editor rewrite the shared link item or create a referral" do
      sign_in student
      expect do
        post(referrals_path(format: :js), params: create_referral_params("https://evil.example"))
      end.not_to change(Referral, :count)
      expect(link_item.reload.link).to eq("https://legit.example")
    end
  end
end
