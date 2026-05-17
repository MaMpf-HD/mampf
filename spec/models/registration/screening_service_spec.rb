require "rails_helper"

RSpec.describe(Registration::ScreeningService) do
  describe "#call" do
    let(:campaign) do
      create(:registration_campaign, :with_items, :preference_based, status: :draft)
    end
    let(:item1) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:invalid_user) { create(:confirmed_user, email: "invalid@other.test") }
    let(:valid_user) { create(:confirmed_user, email: "valid@uni.edu") }
    let!(:policy) do
      create(:registration_policy,
             :institutional_email,
             :for_finalization,
             registration_campaign: campaign,
             config: { "allowed_domains" => "uni.edu" })
    end
    let!(:invalid_registration_a) do
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: item1,
             user: invalid_user,
             preference_rank: 1,
             status: :pending)
    end
    let!(:invalid_registration_b) do
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: item2,
             user: invalid_user,
             preference_rank: 2,
             status: :pending)
    end
    let!(:valid_registration) do
      create(:registration_user_registration,
             registration_campaign: campaign,
             registration_item: item1,
             user: valid_user,
             preference_rank: 3,
             status: :pending)
    end

    it "evaluates each policy once per user while still emitting violations per registration" do
      evaluation_counts = Hash.new(0)

      allow_any_instance_of(Registration::Policy)
        .to receive(:evaluate)
        .and_wrap_original do |method, user|
        evaluation_counts[user.id] += 1
        method.call(user)
      end

      result = described_class.new(campaign, registrations: campaign.user_registrations).call

      expect(evaluation_counts).to eq({ invalid_user.id => 1, valid_user.id => 1 })
      expect(result.violations.pluck(:registration_id))
        .to contain_exactly(invalid_registration_a.id, invalid_registration_b.id)
    end
  end
end
