require "rails_helper"

RSpec.describe(Registration::UserRegistrationsController, type: :controller) do
  let(:user) { create(:user) }
  let(:lecture) { create(:lecture, user: user) }
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:student) { create(:user) }
  let!(:registration) do
    create(:registration_user_registration, registration_campaign: campaign, user: student)
  end

  before do
    sign_in user
  end

  describe "DELETE #destroy" do
    it "destroys the registration" do
      expect do
        delete(:destroy, params: { campaign_id: campaign.id, id: registration.id },
                         format: :turbo_stream)
      end.to change(Registration::UserRegistration, :count).by(-1)
    end

    it "returns success via turbo stream" do
      delete :destroy, params: { campaign_id: campaign.id, id: registration.id },
                       format: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when user is not authorized" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
      end

      it "does not destroy the registration" do
        expect do
          delete(:destroy, params: { campaign_id: campaign.id, id: registration.id },
                           format: :turbo_stream)
        end.not_to change(Registration::UserRegistration, :count)
      end
    end
  end
end
