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

    context "optimization logic (The Greater Good)" do
      let!(:item1) { create(:registration_item, registration_campaign: campaign, capacity: 1) }
      let!(:item2) { create(:registration_item, registration_campaign: campaign, capacity: 1) }
      let!(:user_flexible) { create(:user) }
      let!(:user_inflexible) { create(:user) }

      before do
        # User Flexible: Wants Item 1 (Rank 1) or Item 2 (Rank 2)
        create(:registration_user_registration, user: user_flexible,
                                                registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
        create(:registration_user_registration, user: user_flexible,
                                                registration_campaign: campaign,
                                                registration_item: item2, preference_rank: 2)

        # User Inflexible: Wants Item 1 (Rank 1) only
        create(:registration_user_registration, user: user_inflexible,
                                                registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
      end

      it "assigns the flexible user to their second choice to accommodate the inflexible user" do
        allocation = solver.run

        # Global Cost Analysis:
        # Option 1 (Greedy for Flexible): Flexible->1, Inflexible->Unassigned. Cost: 1 + 1,000,000
        # Option 2 (Social Optimum): Flexible->2, Inflexible->1. Cost: 2 + 1 = 3

        expect(allocation[user_inflexible.id]).to eq(item1.id)
        expect(allocation[user_flexible.id]).to eq(item2.id)
      end
    end

    context "with capacity constraints" do
      let(:solver) { described_class.new(campaign, force_assignments: false) }
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

    context "with force_assignments: true (Forced Assignment)" do
      let(:solver) { described_class.new(campaign, force_assignments: true) }
      let!(:user) { create(:user) }

      it "assigns user to non-preferred item if preferred is full" do
        # Effectively full
        item_full = create(:registration_item, registration_campaign: campaign, capacity: 0)
        item_open = create(:registration_item, registration_campaign: campaign, capacity: 1)

        create(:registration_user_registration, user: user, registration_campaign: campaign,
                                                registration_item: item_full, preference_rank: 1)

        allocation = solver.run
        expect(allocation[user.id]).to eq(item_open.id)
      end

      it "assigns as many as possible if assignment is infeasible (total capacity < users)" do
        # 2 Users, 1 Spot. Forced assignment means everyone MUST be assigned.
        item = create(:registration_item, registration_campaign: campaign, capacity: 1)
        user1 = create(:user)
        user2 = create(:user)
        create(:registration_user_registration, user: user1,
                                                registration_campaign: campaign,
                                                registration_item: item, preference_rank: 1)
        create(:registration_user_registration, user: user2,
                                                registration_campaign: campaign,
                                                registration_item: item, preference_rank: 1)

        allocation = solver.run
        expect(allocation.size).to eq(1)
        expect([user1.id, user2.id]).to include(allocation.keys.first)
      end

      it "fills all available capacity even if it requires forced assignments, " \
         "leaving excess users unassigned" do
        # Total Capacity: 3 (1+1+1)
        item1 = create(:registration_item, registration_campaign: campaign, capacity: 1)
        item2 = create(:registration_item, registration_campaign: campaign, capacity: 1)
        item3 = create(:registration_item, registration_campaign: campaign, capacity: 1)

        # 5 Users
        users = create_list(:user, 5)

        # Users 0, 1, 2 want Item 1
        users[0..2].each do |u|
          create(:registration_user_registration, user: u, registration_campaign: campaign,
                                                  registration_item: item1, preference_rank: 1)
        end

        # Users 3, 4 want Item 2
        users[3..4].each do |u|
          create(:registration_user_registration, user: u, registration_campaign: campaign,
                                                  registration_item: item2, preference_rank: 1)
        end

        # Item 3 is unwanted.

        allocation = solver.run

        # Expect 3 users to be assigned (filling all items)
        expect(allocation.size).to eq(3)

        # Verify Item 1 is taken (by one of 0,1,2)
        expect(allocation.values).to include(item1.id)

        # Verify Item 2 is taken (by one of 3,4)
        expect(allocation.values).to include(item2.id)

        # Verify Item 3 is taken (Forced assignment)
        expect(allocation.values).to include(item3.id)
      end
    end

    context "capacity edge cases" do
      it "respects zero capacity" do
        item = create(:registration_item, registration_campaign: campaign, capacity: 0)
        user = create(:user)
        create(:registration_user_registration, user: user, registration_campaign: campaign,
                                                registration_item: item, preference_rank: 1)

        allocation = solver.run
        expect(allocation).not_to have_key(user.id)
      end
    end

    context "complex scenario (Chain Reaction)" do
      # 5 Items. Items 0-3 have Cap 2. Item 4 has Cap 3. Total Cap 11.
      # 11 Users.
      # We construct a chain where everyone is bumped down one slot to fit the last person.

      let!(:items) do
        create_list(:registration_item, 4, registration_campaign: campaign, capacity: 2)
      end
      let!(:last_item) { create(:registration_item, registration_campaign: campaign, capacity: 3) }
      let(:all_items) { items + [last_item] } # Indices 0..4

      let(:users) { create_list(:user, 11) }

      before do
        # Users 0, 2, 4, 6, 8 are "Stationary" - they just want their item (Rank 1)
        # Users 1, 3, 5, 7 are "Mobile" - they want Item N (Rank 1) but will
        # accept Item N+1 (Rank 2)
        # User 9, 10 just want last item.

        # Item 0 (Cap 2):
        # - User 0 (Rank 1)
        # - User 1 (Rank 1) -> Fallback Item 1
        # - User 10 (Rank 1) [The Pressure]
        # Result: User 1 must move.
        create(:registration_user_registration, user: users[0], registration_campaign: campaign,
                                                registration_item: all_items[0], preference_rank: 1)
        create(:registration_user_registration, user: users[1], registration_campaign: campaign,
                                                registration_item: all_items[0], preference_rank: 1)
        create(:registration_user_registration, user: users[1], registration_campaign: campaign,
                                                registration_item: all_items[1], preference_rank: 2)
        create(:registration_user_registration, user: users[10], registration_campaign: campaign,
                                                registration_item: all_items[0], preference_rank: 1)

        # Item 1 (Cap 2):
        # - User 2 (Rank 1)
        # - User 3 (Rank 1) -> Fallback Item 2
        # Result: User 3 must move (because User 1 is coming).
        create(:registration_user_registration, user: users[2], registration_campaign: campaign,
                                                registration_item: all_items[1], preference_rank: 1)
        create(:registration_user_registration, user: users[3], registration_campaign: campaign,
                                                registration_item: all_items[1], preference_rank: 1)
        create(:registration_user_registration, user: users[3], registration_campaign: campaign,
                                                registration_item: all_items[2], preference_rank: 2)

        # Item 2 (Cap 2):
        # - User 4 (Rank 1)
        # - User 5 (Rank 1) -> Fallback Item 3
        # Result: User 5 must move (because User 3 is coming).
        create(:registration_user_registration, user: users[4], registration_campaign: campaign,
                                                registration_item: all_items[2], preference_rank: 1)
        create(:registration_user_registration, user: users[5], registration_campaign: campaign,
                                                registration_item: all_items[2], preference_rank: 1)
        create(:registration_user_registration, user: users[5], registration_campaign: campaign,
                                                registration_item: all_items[3], preference_rank: 2)

        # Item 3 (Cap 2):
        # - User 6 (Rank 1)
        # - User 7 (Rank 1) -> Fallback Item 4
        # Result: User 7 must move (because User 5 is coming).
        create(:registration_user_registration, user: users[6], registration_campaign: campaign,
                                                registration_item: all_items[3], preference_rank: 1)
        create(:registration_user_registration, user: users[7], registration_campaign: campaign,
                                                registration_item: all_items[3], preference_rank: 1)
        create(:registration_user_registration, user: users[7], registration_campaign: campaign,
                                                registration_item: all_items[4], preference_rank: 2)

        # Item 4 (Cap 3):
        # - User 8 (Rank 1)
        # - User 9 (Rank 1)
        # Result: Everyone fits (User 8, 9, and incoming 7).
        create(:registration_user_registration, user: users[8], registration_campaign: campaign,
                                                registration_item: all_items[4], preference_rank: 1)
        create(:registration_user_registration, user: users[9], registration_campaign: campaign,
                                                registration_item: all_items[4], preference_rank: 1)
      end

      it "shifts users along the chain to accommodate everyone" do
        allocation = solver.run

        # Verify everyone is assigned
        expect(allocation.keys.size).to eq(11)

        # Verify the chain reaction
        expect(allocation[users[1].id]).to eq(all_items[1].id) # Moved to 2nd choice
        expect(allocation[users[3].id]).to eq(all_items[2].id) # Moved to 2nd choice
        expect(allocation[users[5].id]).to eq(all_items[3].id) # Moved to 2nd choice
        expect(allocation[users[7].id]).to eq(all_items[4].id) # Moved to 2nd choice

        # Verify stationary users kept their spots
        expect(allocation[users[10].id]).to eq(all_items[0].id)
        expect(allocation[users[0].id]).to eq(all_items[0].id)
        expect(allocation[users[9].id]).to eq(all_items[4].id)
      end
    end
  end
end
