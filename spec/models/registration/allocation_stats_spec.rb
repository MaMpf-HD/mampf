require "rails_helper"

RSpec.describe(Registration::AllocationStats) do
  let(:campaign) { create(:registration_campaign, :preference_based) }
  let(:item1) { create(:registration_item, registration_campaign: campaign) }
  let(:item2) { create(:registration_item, registration_campaign: campaign) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  before do
    # User 1: Item 1 (Rank 1), Item 2 (Rank 2)
    create(:registration_user_registration, user: user1, registration_campaign: campaign,
                                            registration_item: item1, preference_rank: 1)
    create(:registration_user_registration, user: user1, registration_campaign: campaign,
                                            registration_item: item2, preference_rank: 2)

    # User 2: Item 2 (Rank 1)
    create(:registration_user_registration, user: user2, registration_campaign: campaign,
                                            registration_item: item2, preference_rank: 1)
  end

  describe "#calculate" do
    context "with a mix of assignments" do
      let(:assignment) do
        {
          user1.id => item1.id, # Rank 1
          user2.id => item1.id # Forced (User 2 wanted Item 2)
          # User 3 not assigned
        }
      end

      before do
        # User 3: Item 1 (Rank 1) - Unassigned
        create(:registration_user_registration, user: user3, registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
      end

      subject(:stats) { described_class.new(campaign, assignment) }

      it "calculates total and unassigned users" do
        expect(stats.total_registrations).to eq(3)
        expect(stats.assigned_users).to eq(2)
        expect(stats.unassigned_users).to eq(1)
      end

      it "calculates preference counts" do
        # User 1 got Rank 1.
        # User 2 got Forced.
        expect(stats.preference_counts[1]).to eq(1)
        expect(stats.preference_counts[:forced]).to eq(1)
      end

      it "calculates item stats" do
        # Item 1: User 1 (Rank 1) + User 2 (Forced)
        item_stats = stats.items[item1.id]
        expect(item_stats[:count]).to eq(2)
        expect(item_stats[:forced]).to eq(1)
        # Avg rank: Only non-forced count. User 1 (Rank 1). Avg = 1.0
        expect(item_stats[:avg_rank]).to eq(1.0)
      end

      it "calculates global metrics" do
        # Global Avg Rank:
        # User 1: Rank 1.
        # User 2: Forced (excluded).
        # Sum = 1. Count = 1. Avg = 1.0.
        expect(stats.global_avg_rank).to eq(1.0)

        # Percent Top Choice:
        # 1 user got top choice out of 2 assigned.
        expect(stats.percent_top_choice).to eq(50.0)
      end
    end

    context "when order of registrations is mixed" do
      let(:user_mixed) { create(:user) }
      before do
        # Create Rank 2 FIRST, then Rank 1.
        create(:registration_user_registration, user: user_mixed, registration_campaign: campaign,
                                                registration_item: item2, preference_rank: 2)
        create(:registration_user_registration, user: user_mixed, registration_campaign: campaign,
                                                registration_item: item1, preference_rank: 1)
      end

      let(:assignment) { { user_mixed.id => item1.id } } # Should be Rank 1

      it "correctly identifies rank regardless of creation order" do
        stats = described_class.new(campaign, assignment)
        expect(stats.preference_counts[1]).to eq(1)
        expect(stats.preference_counts[2]).to eq(0)
      end
    end
  end

  describe "#percentage_of_assigned" do
    let(:assignment) { {} }
    subject(:stats) { described_class.new(campaign, assignment) }

    it "returns 0 if no assigned users" do
      allow(stats).to receive(:assigned_users).and_return(0)
      expect(stats.percentage_of_assigned(5)).to eq(0)
    end

    it "calculates percentage correctly" do
      allow(stats).to receive(:assigned_users).and_return(10)
      expect(stats.percentage_of_assigned(2)).to eq(20.0)
    end
  end
end
