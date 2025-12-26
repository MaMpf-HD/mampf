require "rails_helper"
require "nokogiri"

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

    context "with open + fcfs lecture campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served, :open,
                          :with_policies, self_registerable: true)
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
