require "rails_helper"
require "nokogiri"

RSpec.describe("Registration::UserRegistrations", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: user) }
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:student) { create(:confirmed_user) }
  let!(:registration) do
    create(:registration_user_registration, registration_campaign: campaign, user: student)
  end

  before do
    Flipper.enable(:registration_campaigns)
    sign_in user
  end

  describe "DELETE /campaigns/:campaign_id/registrations/user/:user_id" do
    let(:path) do
      destroy_for_user_registration_campaign_registrations_path(campaign, user_id: student.id)
    end

    it "destroys the registration" do
      expect do
        delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
      end.to change(Registration::UserRegistration, :count).by(-1)
    end

    it "returns success via turbo stream" do
      delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when user is not authorized" do
      let(:other_user) { create(:confirmed_user) }

      before do
        sign_in other_user
      end

      it "does not destroy the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)
      end

      it "redirects to root" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when campaign does not exist" do
      let(:path) do
        destroy_for_user_registration_campaign_registrations_path(registration_campaign_id: -1,
                                                                  user_id: student.id)
      end

      it "redirects to root with error" do
        delete path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.not_found"))
      end
    end

    context "when campaign is completed" do
      before do
        campaign.update!(status: :completed)
      end

      it "does not destroy the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)
      end

      it "shows error message" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include(I18n.t("registration.campaign.errors.already_finalized"))
      end
    end
  end
end

RSpec.describe("Registration::UserRegistrations", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }
  let(:seminar) { create(:lecture, :is_seminar) }

  before do
    Flipper.enable(:registration_campaigns)
    sign_in user
  end

  describe "GET campaign_registrations/:campaign_id" do
    context "with draft campaign" do
      let(:campaign) { FactoryBot.create(:registration_campaign) }
      it "re-route when campaign is draft" do
        get campaign_registrations_for_campaign_path(campaign_id: campaign.id)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "should display multi select mode with open + fcfs tutorial campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served, :open,
                          :with_policies)
      end
      it "return success response" do
        get campaign_registrations_for_campaign_path(campaign_id: campaign.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css('[data-test="multi-item-fcfs"]')).not_to be_nil
      end
    end

    context "should display multi select mode with open + fcfs talks campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served, :open, :with_policies,
                          campaignable: seminar)
      end
      it "return success response" do
        get campaign_registrations_for_campaign_path(campaign_id: campaign.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css('[data-test="multi-item-fcfs"]')).not_to be_nil
      end
    end

    context "should display result with completed campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served,
                          :completed_after_policies, campaignable: seminar)
      end
      it "return success response" do
        get campaign_registrations_for_campaign_path(campaign_id: campaign.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css('[data-test="result"]')).not_to be_nil
      end
    end
  end
end
