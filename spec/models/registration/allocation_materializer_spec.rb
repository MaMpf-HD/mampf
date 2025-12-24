require "rails_helper"

RSpec.describe(Registration::AllocationMaterializer, type: :model) do
  let(:campaign) { create(:registration_campaign, :with_items, status: :processing) }
  let(:item) { campaign.registration_items.first }
  let(:user) { create(:user) }
  let(:materializer) { described_class.new(campaign) }

  before do
    create(:registration_user_registration, :confirmed, registration_item: item, user: user,
                                                        registration_campaign: campaign)
  end

  describe "#materialize!" do
    it "delegates to registerable#materialize_allocation!" do
      # Force the query to return our specific item instance so we can set expectations on it
      allow(campaign).to receive_message_chain(:registration_items, :includes,
                                               :find_each).and_yield(item)

      expect(item.registerable).to receive(:materialize_allocation!).with(
        user_ids: [user.id],
        campaign: campaign
      )

      materializer.materialize!
    end
  end
end
