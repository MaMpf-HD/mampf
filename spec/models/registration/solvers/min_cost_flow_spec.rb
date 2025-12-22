require "rails_helper"

RSpec.describe(Registration::Solvers::MinCostFlow) do
  let(:campaign) { create(:registration_campaign, :preference_based) }
  let(:solver) { described_class.new(campaign) }

  describe "#run" do
    context "when no users are registered" do
      it "returns an empty hash" do
        expect(solver.run).to eq({})
      end
    end

    context "with simple allocation scenario" do
      let!(:item1) { create(:registration_item, registration_campaign: campaign, capacity: 1) }
      let!(:item2) { create(:registration_item, registration_campaign: campaign, capacity: 1) }

      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }

      before do
        # User 1 prefers Item 1 (Rank 1)
        create(:registration_user_registration, user: user1, registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
        # User 2 prefers Item 1 (Rank 1) and Item 2 (Rank 2)
        create(:registration_user_registration, user: user2, registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
        create(:registration_user_registration, user: user2, registration_campaign: campaign,
                                                registration_item: item2, preference_rank: 2)
      end

      it "allocates optimally" do
        # Optimal: User 1 -> Item 1, User 2 -> Item 2
        # Cost: 1 + 2 = 3
        # Alternative: User 1 -> Unassigned (Cost 1M),
        # User 2 -> Item 1 (Cost 1) -> Total 1M+1 (Worse)

        allocation = solver.run
        expect(allocation[user1.id]).to eq(item1.id)
        expect(allocation[user2.id]).to eq(item2.id)
      end
    end

    context "with capacity constraints" do
      let!(:item1) { create(:registration_item, registration_campaign: campaign, capacity: 1) }
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }

      before do
        create(:registration_user_registration, user: user1, registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
        create(:registration_user_registration, user: user2, registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
      end

      it "allocates to one and leaves other unassigned (or assigned to dummy)" do
        allocation = solver.run

        assigned_users = allocation.keys
        expect(assigned_users.size).to eq(1)
        expect([user1.id, user2.id]).to include(assigned_users.first)
      end
    end
  end
end
