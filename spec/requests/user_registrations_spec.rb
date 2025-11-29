require "rails_helper"
require "nokogiri"

RSpec.describe("Registration::UserRegistrations", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { FactoryBot.create(:lecture) }

  before do
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

    context "with open + fcfs lecture campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served, :open,
                          :with_policies, :for_lecture_enrollment)
      end
      it "return success response" do
        get campaign_registrations_for_campaign_path(campaign_id: campaign.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css('[data-test="single-item-fcfs"]')).not_to be_nil
      end
    end

    context "should display multi select mode with open + fcfs tutorial campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served, :open,
                          :with_policies, :for_tutorial_enrollment)
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
        FactoryBot.create(:registration_campaign, :first_come_first_served, :open,
                          :with_policies, :for_talk_enrollment)
      end
      it "return success response" do
        get campaign_registrations_for_campaign_path(campaign_id: campaign.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css('[data-test="multi-item-fcfs"]')).not_to be_nil
      end
    end
  end
end
