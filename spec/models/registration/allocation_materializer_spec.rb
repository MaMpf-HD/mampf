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
      # Mock the chain to return our specific item
      relation = double("ActiveRecord::Relation")
      allow(campaign).to receive(:registration_items).and_return(relation)
      allow(relation).to receive(:includes).with(:registerable).and_return(relation)
      allow(relation).to receive(:find_each).and_yield(item)

      expect(item.registerable).to receive(:materialize_allocation!).with(
        user_ids: [user.id],
        campaign: campaign
      )

      materializer.materialize!
    end

    it "updates the materialized_at timestamp for confirmed registrations" do
      relation = double("ActiveRecord::Relation")
      allow(campaign).to receive(:registration_items).and_return(relation)
      allow(relation).to receive(:includes).with(:registerable).and_return(relation)
      allow(relation).to receive(:find_each).and_yield(item)
      allow(item.registerable).to receive(:materialize_allocation!)

      expect do
        materializer.materialize!
      end.to change {
               user.user_registrations.find_by(registration_item: item)
                   .reload.materialized_at
             }.from(nil)
    end
  end
end
