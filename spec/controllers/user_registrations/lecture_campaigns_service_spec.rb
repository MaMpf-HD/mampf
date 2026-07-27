require "rails_helper"

RSpec.describe(UserRegistrations::LectureCampaignsService, type: :service) do
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
      details_open      = instance_double(UserRegistrations::CampaignDetailsService::Result)
      details_completed = instance_double(UserRegistrations::CampaignDetailsService::Result)

      expect(UserRegistrations::CampaignDetailsService)
        .to receive(:new)
        .with(campaign_open, user)
        .and_return(instance_double(UserRegistrations::CampaignDetailsService,
                                    call: details_open))

      expect(UserRegistrations::CampaignDetailsService)
        .to receive(:new)
        .with(campaign_completed, user)
        .and_return(instance_double(UserRegistrations::CampaignDetailsService,
                                    call: details_completed))

      # Draft campaign must NOT be processed
      expect(UserRegistrations::CampaignDetailsService)
        .not_to receive(:new)
        .with(campaign_draft, anything)

      result = service.call

      expect(result).to eq([details_open, details_completed])
    end

    it "returns campaign details when a join-only tutorial blocks changes" do
      tutorial = create(:tutorial,
                        lecture: lecture,
                        skip_campaigns: true,
                        self_materialization_mode: :add_only)
      tutorial.add_user_to_roster!(user)

      details_open      = instance_double(UserRegistrations::CampaignDetailsService::Result)
      details_completed = instance_double(UserRegistrations::CampaignDetailsService::Result)

      expect(UserRegistrations::CampaignDetailsService)
        .to receive(:new)
        .with(campaign_open, user)
        .and_return(instance_double(UserRegistrations::CampaignDetailsService,
                                    call: details_open))

      expect(UserRegistrations::CampaignDetailsService)
        .to receive(:new)
        .with(campaign_completed, user)
        .and_return(instance_double(UserRegistrations::CampaignDetailsService,
                                    call: details_completed))

      result = service.call

      expect(result).to eq([details_open, details_completed])
    end
  end
end
