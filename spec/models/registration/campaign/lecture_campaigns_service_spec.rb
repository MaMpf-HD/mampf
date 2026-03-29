require "rails_helper"

RSpec.describe(Registration::Campaign::LectureCampaignsService, type: :service) do
  let(:user)    { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }

  let!(:campaign_open) do
    create(:registration_campaign, :open, campaignable: lecture)
  end

  let!(:campaign_completed) do
    create(:registration_campaign, :completed, campaignable: lecture)
  end

  let!(:campaign_draft) do
    create(:registration_campaign, :draft, campaignable: lecture)
  end

  subject(:service) { described_class.new(lecture, user) }

  describe "#call" do
    it "returns details for all non-draft campaigns" do
      details_open      = instance_double(Registration::Campaign::CampaignDetailsService::Result)
      details_completed = instance_double(Registration::Campaign::CampaignDetailsService::Result)

      expect(Registration::Campaign::CampaignDetailsService)
        .to receive(:new)
        .with(campaign_open, user)
        .and_return(instance_double(Registration::Campaign::CampaignDetailsService,
                                    call: details_open))

      expect(Registration::Campaign::CampaignDetailsService)
        .to receive(:new)
        .with(campaign_completed, user)
        .and_return(instance_double(Registration::Campaign::CampaignDetailsService,
                                    call: details_completed))

      # Draft campaign must NOT be processed
      expect(Registration::Campaign::CampaignDetailsService)
        .not_to receive(:new)
        .with(campaign_draft, anything)

      result = service.call

      expect(result).to eq([details_open, details_completed])
    end
  end
end
